import asyncio
import base64
import io
import logging
import os

from app.config import settings

logger = logging.getLogger(__name__)

# Use HF mirror for model downloads in China
os.environ.setdefault("HF_ENDPOINT", "https://hf-mirror.com")


class ASRError(Exception):
    """Raised when ASR transcription fails."""
    pass


class ASRService:
    """Speech recognition service with multiple backends.

    v0.1 uses OpenAI Whisper (offline, works in China).
    FunASR (paraformer-zh) is reserved for v0.2 / on-premise.
    """

    def __init__(self) -> None:
        self.enabled = settings.asr_enabled
        self.model: object | None = None
        self.backend = "whisper"

    async def initialize(self) -> None:
        """Initialize the ASR backend.

        Priority: Whisper (offline) > FunASR (if configured) > Google (last resort).
        """
        if not self.enabled:
            logger.info("ASR is disabled (asr_enabled=false)")
            return

        try:
            self._init_whisper()
        except Exception as e:
            logger.warning("Whisper init failed: %s", e)

        if self.model is None and settings.asr_model == "paraformer-zh":
            try:
                await self._init_funasr()
            except Exception as e:
                logger.warning("FunASR init failed: %s", e)

        if self.model is None:
            self._init_google()

        if self.model is None:
            logger.warning("All ASR backends failed — voice input disabled")
            self.enabled = False

    def _init_whisper(self) -> None:
        try:
            from faster_whisper import WhisperModel
            self.model = WhisperModel(
                "tiny", device="cpu", compute_type="int8",
                download_root="/tmp/whisper-models",
            )
            self.backend = "whisper"
            logger.info("ASR using Faster-Whisper (tiny model, offline)")
        except ImportError:
            logger.warning("faster-whisper not installed, falling back to Google Speech Recognition")
            self._init_google()
        except Exception as e:
            logger.error("Failed to load Whisper model: %s, falling back to Google", e)
            self._init_google()

    async def _init_funasr(self) -> None:
        try:
            from funasr import AutoModel
            self.model = AutoModel(model=settings.asr_model)
            self.backend = "funasr"
            logger.info("ASR model loaded: %s (funasr)", settings.asr_model)
        except ImportError:
            logger.warning("FunASR not installed, falling back to Google Speech Recognition")
            self._init_google()
        except Exception as e:
            logger.error("Failed to load FunASR model: %s, falling back to Google", e)
            self._init_google()

    def _init_google(self) -> None:
        try:
            import speech_recognition as sr
            self.model = sr.Recognizer()
            self.backend = "google"
            logger.info("ASR using Google Web Speech API")
        except ImportError:
            logger.warning("speech_recognition not installed, ASR unavailable")
            self.model = None
            self.enabled = False
        except Exception as e:
            logger.error("Failed to init Google ASR: %s", e)
            self.model = None
            self.enabled = False

    async def transcribe(self, audio_base64: str) -> str:
        """Transcribe base64-encoded audio to text."""
        if not self.enabled or self.model is None:
            raise ASRError("ASR is not available")

        try:
            audio_bytes = base64.b64decode(audio_base64)
        except ValueError as e:
            raise ASRError(f"Invalid audio base64: {e}") from e

        try:
            if self.backend == "funasr":
                return await self._transcribe_funasr(audio_bytes)
            elif self.backend == "whisper":
                return await self._transcribe_whisper(audio_bytes)
            else:
                return await self._transcribe_google(audio_bytes)
        except ASRError:
            raise
        except Exception as e:
            raise ASRError(f"Transcription failed: {e}") from e

    async def _transcribe_whisper(self, audio_bytes: bytes) -> str:
        import tempfile
        import os

        def _do_recognize() -> str:
            with tempfile.NamedTemporaryFile(suffix=".wav", delete=False) as f:
                f.write(audio_bytes)
                tmp_path = f.name
            try:
                segments, _ = self.model.transcribe(tmp_path, language="zh")
                return "".join(seg.text for seg in segments).strip()
            finally:
                os.unlink(tmp_path)

        text = await asyncio.to_thread(_do_recognize)
        if not text:
            raise ASRError("No transcription result")
        return text

    async def _transcribe_funasr(self, audio_bytes: bytes) -> str:
        result = await asyncio.to_thread(self.model.generate, input=audio_bytes)
        if result and len(result) > 0:
            text = result[0].get("text", "")
            return text.strip()
        raise ASRError("No transcription result")

    async def _transcribe_google(self, audio_bytes: bytes) -> str:
        import speech_recognition as sr

        def _do_recognize() -> str:
            wav_io = io.BytesIO(audio_bytes)
            with sr.AudioFile(wav_io) as source:
                audio = self.model.record(source)
            return self.model.recognize_google(audio, language="zh-CN")

        try:
            text = await asyncio.to_thread(_do_recognize)
            return text.strip()
        except sr.UnknownValueError:
            raise ASRError("Google Speech Recognition could not understand audio")
        except sr.RequestError as e:
            raise ASRError(f"Google Speech Recognition request failed: {e}")
        except ASRError:
            raise
        except Exception as e:
            raise ASRError(f"Speech recognition failed: {e}")

    def is_available(self) -> bool:
        return self.enabled and self.model is not None
