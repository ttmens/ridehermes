import importlib.resources


def load_prompt_template(name: str) -> str:
    """Load a prompt template from the templates directory."""
    try:
        ref = importlib.resources.files("app.prompts.templates").joinpath(name)
        return ref.read_text(encoding="utf-8")
    except (FileNotFoundError, ModuleNotFoundError):
        # Fallback for development without installed package
        import os
        tmpl_path = os.path.join(os.path.dirname(__file__), "templates", name)
        if os.path.exists(tmpl_path):
            with open(tmpl_path, encoding="utf-8") as f:
                return f.read()
        return ""


def build_system_prompt() -> str:
    """Build the system prompt for ride-hailing intent parsing."""
    base = load_prompt_template("ride_booking.txt")
    few_shot = load_prompt_template("ride_booking_few_shot.txt")
    if few_shot:
        return base + "\n\n" + few_shot
    return base


WEEKDAY_NAMES = ["一", "二", "三", "四", "五", "六", "日"]


def build_messages(text: str, history: list[dict[str, str]] | None = None) -> list[dict[str, str]]:
    """Build the full message list for LLM call, with current time injected."""
    from datetime import datetime

    system = build_system_prompt()

    # Inject current time so LLM can resolve relative times (e.g., "明天早上8点")
    now = datetime.now()
    time_hint = (
        f"\n\n## 当前时间\n"
        f"现在是 {now.strftime('%Y年%m月%d日 %H:%M')}，"
        f"星期{WEEKDAY_NAMES[now.weekday()]}。"
    )
    system += time_hint

    messages = [{"role": "system", "content": system}]

    if history:
        messages.extend(history[-12:])  # Keep last 12 messages (6 turns)

    messages.append({"role": "user", "content": text})
    return messages
