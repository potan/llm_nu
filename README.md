# llm_nu
Access to llms from nu.

Store your tokens in tokens.json
```json
{
  "openrouterai": "...",
  "deepseek": "..."
}
```

Use
```nushell
source ai.nu
ai completions --api openrouterai --model "stepfun/step-3.5-flash:free" --tools [{"type": "function", "function": {"name": "get_weather", "description": "Get the weather in a given city", "parameters": {"type": "object", "properties": {"city": {"type": "string", "description": "The city to get the weather for" } }, "required": ["city"] } }}] [{role: system, content: "You are a helpful assistant."}, {role: user, content: "what is the weather in tokyo?"}]
```
