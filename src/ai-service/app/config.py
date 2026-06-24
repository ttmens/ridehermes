from pydantic_settings import BaseSettings


class Settings(BaseSettings):
    # Server
    host: str = "0.0.0.0"
    port: int = 8001
    log_level: str = "info"

    # LLM
    llm_base_url: str = "https://dashscope.aliyuncs.com/compatible-mode/v1"
    llm_api_key: str = ""
    llm_model: str = "qwen2.5-72b-instruct"
    llm_max_tokens: int = 4096
    llm_temperature: float = 0.1
    llm_timeout: int = 30

    # ASR — uses faster-whisper tiny model (offline, works in China)
    asr_enabled: bool = True
    asr_model: str = "whisper-tiny"

    # AMap Geocoding
    amap_api_key: str = ""

    # Redis
    redis_url: str = "redis://localhost:6379/0"
    redis_max_history: int = 20

    model_config = {"env_file": ".env", "env_file_encoding": "utf-8"}


settings = Settings()
