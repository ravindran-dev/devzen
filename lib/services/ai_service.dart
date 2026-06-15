class AIService {
  Future<String> processCommand(String command, String context) async {
    await Future.delayed(const Duration(milliseconds: 1500));
    final cmd = command.toLowerCase();

    if (cmd.contains('explain') || cmd.contains('code')) {
      return '''### Code Explanation

Here is a breakdown of the provided logic:

1. **State Injection**: Uses a reactive dependency injection model to share values down the widget tree without rebuilding ancestors.
2. **Backdrop Filter**: Implements native pixel-shaders to blur overlapping layers, creating a premium frosted glass UI.
3. **Optimized Painting**: Drawing on the canvas avoids heavy DOM operations, ensuring a solid 60 FPS on mobile.

**Performance Suggestion**: Cache the shader representation using a `RepaintBoundary` to prevent unnecessary paint passes.''';
    }

    if (cmd.contains('debug') || cmd.contains('error')) {
      return '''### Debug Report

**Identified Issue**: `NullThrownError` on line 42.

**Root Cause**: The async resource fetcher is updating the UI state after the enclosing component has already been unmounted from the tree.

**Fix**:
```dart
// Check if the state node is active before writing state updates
if (mounted) {
  setState(() {
    _isLoading = false;
  });
}
```''';
    }

    if (cmd.contains('readme') || cmd.contains('documentation')) {
      return '''# DevZen Workspace

A premium developer workspace app.

## Getting Started
1. Install dependencies:
   ```bash
   flutter pub get
   ```
2. Run in developer mode:
   ```bash
   flutter run
   ```

## License
MIT''';
    }

    if (cmd.contains('architecture')) {
      return '''### Clean Architecture Framework

For scalable mobile apps, structure the code in 3 distinct layers:

1. **Domain (Core)**: Entities, Value Objects, and abstract Repository contracts (strictly business rules).
2. **Data**: Repository implementations, HTTP clients, Local DB database adapters (external sources).
3. **Presentation**: Providers, UI Views, Custom widgets, animations (user-facing screens).''';
    }

    return '''### DevZen AI Response

I'm ready to assist you! Here are some prompt ideas:
- **Explain**: Analyze code blocks and explain how they operate.
- **Debug**: Pass in an error log or code block to analyze logic flaws.
- **Architecture**: Design structured directory maps or class structures.
- **README**: Write high-quality markdown files for your Git repositories.''';
  }
}
