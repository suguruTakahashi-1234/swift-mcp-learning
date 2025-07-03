import MCP
import Foundation

// MARK: - Data Models

// 天気データの構造体
struct WeatherData {
    let temperature: Double
    let conditions: String
    let humidity: Int
    let windSpeed: Double
}

// システムステータスの構造体
struct SystemStatus {
    let overall: String
    let database: String
    let api: String
    let model: String
    let timestamp: String
}

// MARK: - Helper Functions

// 天気データを取得する関数（モックデータ）
func getWeatherData(location: String, units: String) -> WeatherData {
    // 実際の実装では、天気APIを呼び出します
    let temperature = units == "imperial" ? 75.0 : 24.0
    return WeatherData(
        temperature: temperature,
        conditions: "晴れ",
        humidity: 65,
        windSpeed: units == "imperial" ? 10.0 : 16.0
    )
}

// 数式を評価する関数
func evaluateExpression(_ expression: String) -> String {
    // 簡単な計算の実装
    let cleanExpression = expression.replacingOccurrences(of: " ", with: "")
    
    // 基本的な四則演算のサポート
    if cleanExpression.contains("+") {
        let parts = cleanExpression.components(separatedBy: "+")
        if parts.count == 2,
           let left = Double(parts[0]),
           let right = Double(parts[1]) {
            return String(left + right)
        }
    } else if cleanExpression.contains("-") {
        let parts = cleanExpression.components(separatedBy: "-")
        if parts.count == 2,
           let left = Double(parts[0]),
           let right = Double(parts[1]) {
            return String(left - right)
        }
    } else if cleanExpression.contains("*") {
        let parts = cleanExpression.components(separatedBy: "*")
        if parts.count == 2,
           let left = Double(parts[0]),
           let right = Double(parts[1]) {
            return String(left * right)
        }
    } else if cleanExpression.contains("/") {
        let parts = cleanExpression.components(separatedBy: "/")
        if parts.count == 2,
           let left = Double(parts[0]),
           let right = Double(parts[1]),
           right != 0 {
            return String(left / right)
        }
    }
    
    return "計算エラー: 無効な式です"
}

// システムステータスを取得する関数
func getCurrentSystemStatus() -> SystemStatus {
    let formatter = DateFormatter()
    formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
    let timestamp = formatter.string(from: Date())
    
    return SystemStatus(
        overall: "正常",
        database: "稼働中",
        api: "稼働中",
        model: "稼働中",
        timestamp: timestamp
    )
}

// MARK: - Server Configuration

let server = Server(
    name: "MyMCPServer",
    version: "1.0.0",
    capabilities: Server.Capabilities(
        prompts: Server.Capabilities.Prompts(
            listChanged: true
        ),
        resources: Server.Capabilities.Resources(
            subscribe: true
        ),
        sampling: .init(),
        tools: Server.Capabilities.Tools(
            listChanged: true
        )
    )
)

// MARK: - Tools

await server.withMethodHandler(ListTools.self) { _ in
    let tools = [
        Tool(
            name: "weather",
            description: "指定された場所の現在の天気を取得します",
            inputSchema: .object([
                "properties": .object([
                    "location": .object([
                        "type": .string("string"),
                        "description": .string("都市名または座標")
                    ]),
                    "units": .object([
                        "type": .string("string"),
                        "description": .string("測定単位 (metric または imperial)"),
                        "default": .string("metric")
                    ])
                ]),
                "required": .array([.string("location")])
            ])
        ),
        Tool(
            name: "calculator",
            description: "数学的計算を実行します",
            inputSchema: .object([
                "properties": .object([
                    "expression": .object([
                        "type": .string("string"),
                        "description": .string("評価する数式")
                    ])
                ]),
                "required": .array([.string("expression")])
            ])
        )
    ]
    return .init(tools: tools)
}

await server.withMethodHandler(CallTool.self) { params in
    switch params.name {
    case "weather":
        let location = params.arguments?["location"]?.stringValue ?? "不明"
        let units = params.arguments?["units"]?.stringValue ?? "metric"
        let weatherData = getWeatherData(location: location, units: units)
        let unitsSymbol = units == "imperial" ? "°F" : "°C"
        let windUnits = units == "imperial" ? "mph" : "km/h"
        
        let response = """
        🌤️ \(location)の天気情報:
        気温: \(weatherData.temperature)\(unitsSymbol)
        天候: \(weatherData.conditions)
        湿度: \(weatherData.humidity)%
        風速: \(weatherData.windSpeed) \(windUnits)
        """
        
        return .init(
            content: [.text(response)],
            isError: false
        )

    case "calculator":
        if let expression = params.arguments?["expression"]?.stringValue {
            let result = evaluateExpression(expression)
            return .init(
                content: [.text("計算結果: \(expression) = \(result)")],
                isError: false
            )
        } else {
            return .init(
                content: [.text("エラー: 式パラメータが見つかりません")],
                isError: true
            )
        }

    default:
        return .init(
            content: [.text("エラー: 不明なツール '\(params.name)'")],
            isError: true
        )
    }
}

// MARK: - Resources

await server.withMethodHandler(ListResources.self) { params in
    let resources = [
        Resource(
            name: "ナレッジベース記事",
            uri: "resource://knowledge-base/articles",
            description: "サポート記事とドキュメントのコレクション"
        ),
        Resource(
            name: "システムステータス",
            uri: "resource://system/status",
            description: "現在のシステム運用状況"
        )
    ]
    return .init(resources: resources, nextCursor: nil)
}

await server.withMethodHandler(ReadResource.self) { params in
    switch params.uri {
    case "resource://knowledge-base/articles":
        let content = """
        # ナレッジベース
        
        ## よくある質問
        
        ### Q: このMCPサーバーは何をしますか？
        A: このサーバーは天気情報の取得と計算機能を提供します。
        
        ### Q: サポートされている計算は何ですか？
        A: 基本的な四則演算（+、-、*、/）をサポートしています。
        
        ### Q: 天気情報はリアルタイムですか？
        A: 現在はデモ用のモックデータを使用しています。
        
        ## 使用方法
        
        1. `weather` ツール: 場所と単位を指定して天気情報を取得
        2. `calculator` ツール: 数式を指定して計算を実行
        
        ## トラブルシューティング
        
        - 計算エラーが発生した場合は、式の形式を確認してください
        - サポートされていない演算子は使用できません
        """
        
        return .init(contents: [Resource.Content.text(content, uri: params.uri)])

    case "resource://system/status":
        let status = getCurrentSystemStatus()
        let statusJson = """
            {
                "status": "\(status.overall)",
                "components": {
                    "database": "\(status.database)",
                    "api": "\(status.api)", 
                    "model": "\(status.model)"
                },
                "lastUpdated": "\(status.timestamp)"
            }
            """
        return .init(contents: [Resource.Content.text(statusJson, uri: params.uri, mimeType: "application/json")])

    default:
        throw MCPError.invalidParams("不明なリソースURI: \(params.uri)")
    }
}

// MARK: - Prompts

await server.withMethodHandler(ListPrompts.self) { _ in
    let prompts = [
        Prompt(
            name: "weather-report",
            description: "指定された場所の詳細な天気レポートを生成します"
        ),
        Prompt(
            name: "calculation-help",
            description: "計算機能の使い方を説明します"
        )
    ]
    return .init(prompts: prompts)
}

await server.withMethodHandler(GetPrompt.self) { params in
    switch params.name {
    case "weather-report":
        let location = params.arguments?["location"] ?? "東京"
        let units = params.arguments?["units"] ?? "metric"
        
        let promptText = """
        \(location)の詳細な天気レポートを作成してください。
        
        以下の情報を含めてください:
        - 現在の気温と体感温度
        - 天候の状況
        - 湿度レベル
        - 風の状況
        - 今日の天気の見通し
        - 服装のアドバイス
        
        使用する単位: \(units)
        """
        
        return .init(
            description: "詳細な天気レポートプロンプト",
            messages: [
                .user(.text(text: promptText))
            ]
        )
        
    case "calculation-help":
        let helpText = """
        計算機能の使い方を説明してください。
        
        以下の点について説明してください:
        - サポートされている演算子
        - 計算式の書き方
        - 使用例
        - エラーが発生した場合の対処法
        """
        
        return .init(
            description: "計算機能のヘルプ",
            messages: [
                .user(.text(text: helpText))
            ]
        )
        
    default:
        throw MCPError.invalidParams("不明なプロンプト: \(params.name)")
    }
}

// MARK: - Server Startup

let transport = StdioTransport()
print("MCPサーバーを開始しています...")
try await server.start(transport: transport)
