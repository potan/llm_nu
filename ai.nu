
$env.AI.default = "openrouterai"
$env.AI.history = []
$env.AI.api.openrouterai = {
  url: "https://openrouter.ai/api/v1",
  timeout: 300sec,
  default-model: "openrouter/free",
  token: "",
  models: [
    {id: "openrouter/free"},
    {id: "stepfun/step-3.5-flash:free"},
    {id: "openrouter/auto"}
  ]
}
$env.AI.api.ollama = {
  url: "http://localhost:11434/v1",
  timeout: 300sec,
  default-model: "gemma3",
  token: "",
  models: [{id: "gemma3"}]
}
$env.AI.api.deepseek = {
  url: "https://api.deepseek.com",
  timeout: 300sec,
  default-model: "deepseek-chat",
  token: "",
  models: [{id: "deepseek-chat"}, {id:"deepseek-reasoner"}]
}

def services [] {
  $env.AI.api | columns
}

def models [context: string@services = ""] {
  let api_opt = $context | parse --regex "\\s--api\\s(?P<api>[^\\s]+)\\s?"
  let api = if $api_opt != [] {
    $api_opt | last | get api
  } else {
    if ($context | parse --regex "\\s") == [] { $context } else { $env.AI.default }
  }
  $env.AI.api | get $api | get models | get id
}

def --env load_models [--api: string@services = "", --token: string = "", --timeout: duration = 0sec] {
  let api_name = if $api == "" { $env.AI.default } else { $api }
  let api = $env.AI.api | get $api_name
  let url = $api.url
  let token = if $token == "" { $api.token } else { $token }
  let timeout = if $timeout == 0sec { $api.timeout } else { $timeout }

  let auth = if $token == "" { {} } else { { Authorization: $"Bearer ($token)" } }

  let models = http get --max-time $timeout --headers ({ Content-Type: application/json } | merge $auth) $"($url)/models"
  $env.AI.api = $env.AI.api | update $api_name { $in | merge { models: $models.data } }
  $models
}

def --env "set token" [--api: string@services = "", token: string] {
  let api = if $api == "" { $env.AI.default } else { $api }
  $env.AI.api = $env.AI.api | update $api { $in | merge { token: $token } }
}

def load_tokens --env [] {
  let tokens = open tokens.json
  for api in ($tokens | columns) {
    set token --api $api ($tokens | get $api)
  }
}

load_tokens

def --env "ai completions" [--api: string@services = "", --token: string = "", --timeout: duration = 0sec, --model: string@models = "", --tools = [] --stream = false, message: any] {
  let api_name = if $api == "" { $env.AI.default } else { $api }
  let api = $env.AI.api | get $api_name
  let url = $api.url
  let token = if $token == "" { $api.token } else { $token }
  let model = if $model == "" { $api.default-model } else { $model }
  let timeout = if $timeout == 0sec { $api.timeout } else { $timeout }

  let auth = if $token == "" { {} } else { { Authorization: $"Bearer ($token)" } }
  let query = { model: $model, messages: $message, stream: $stream } | merge (if tools == [] { {} } else { { tools: $tools } })
  let resp = http post --max-time $timeout --headers ({ Content-Type: application/json } | merge $auth) --content-type application/json $"($url)/chat/completions" $query
  $env.AI.history = $env.AI.history | append {service: $api_name, model: $model, query: $query}
  $resp
}
