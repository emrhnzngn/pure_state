import 'package:pure_state/pure_state.dart';
import 'package:flutter/material.dart';

/// A widget that displays a floating debugger tool for EzState.
///
/// Wraps the [child] and provides a floating action button or overlay
/// to open a debug panel showing:
/// - Action History
/// - Current State
/// - Errors
class PureDebugger extends StatefulWidget {
  /// The child widget.
  final Widget child;

  /// Whether the debugger is enabled initially.
  final bool enabled;

  const PureDebugger({
    required this.child,
    this.enabled = true,
    super.key,
  });

  @override
  State<PureDebugger> createState() => _PureDebuggerState();
}

class _PureDebuggerState extends State<PureDebugger> {
  final List<_DebugEvent> _events = [];
  bool _isOpen = false;

  @override
  void initState() {
    super.initState();
    if (widget.enabled) {
      _attachMiddleware();
    }
  }

  void _attachMiddleware() {
    PureStore.addGlobalMiddleware(_debuggerMiddleware);
  }

  @override
  void dispose() {
    PureStore.removeGlobalMiddleware(_debuggerMiddleware);
    super.dispose();
  }

  void _debuggerMiddleware(
    Object store,
    Object action,
    void Function(Object action) next,
  ) {
    final startTime = DateTime.now();
    try {
      next(action);
      
      // Post-execution (synchronous part)
      final endTime = DateTime.now();
      final duration = endTime.difference(startTime);
      
      _addEvent(
        _DebugEvent(
          type: _EventType.action,
          timestamp: startTime,
          store: store.runtimeType.toString(),
          action: action.toString(),
          duration: duration,
        ),
      );
    } catch (e) {
       _addEvent(
        _DebugEvent(
          type: _EventType.error,
          timestamp: startTime,
          store: store.runtimeType.toString(),
          action: action.toString(),
          error: e.toString(),
        ),
      );
      rethrow;
    }
  }

  void _addEvent(_DebugEvent event) {
    if (!mounted) return;
    // Limit history to 100 events
    if (_events.length >= 100) {
      _events.removeAt(0);
    }
    setState(() {
      _events.add(event);
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.enabled) return widget.child;

    return Directionality(
      textDirection: TextDirection.ltr,
      child: Stack(
        children: [
          widget.child,
          if (_isOpen)
            Positioned.fill(
              child: GestureDetector(
                onTap: () => setState(() => _isOpen = false),
                child: Container(
                  color: Colors.black54,
                  child: GestureDetector(
                    onTap: () {}, // Prevent closing when tapping panel
                    child: _buildDebugPanel(),
                  ),
                ),
              ),
            ),
          if (!_isOpen)
            Positioned(
              right: 16,
              bottom: 16,
              child: FloatingActionButton(
                mini: true,
                backgroundColor: Colors.deepPurple,
                child: const Icon(Icons.bug_report, color: Colors.white),
                onPressed: () => setState(() => _isOpen = true),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildDebugPanel() {
    return Align(
      alignment: Alignment.centerRight,
      child: Container(
        width: 350,
        height: double.infinity,
        color: Colors.grey[900],
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: ListView.builder(
                itemCount: _events.length,
                reverse: true, // Show newest at bottom (or top if we reversed list)
                // Actually, let's show newest at TOP.
                itemBuilder: (context, index) {
                  // Reverse index to show newest first
                  final event = _events[_events.length - 1 - index];
                  return _buildEventItem(event);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.grey[850],
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Expanded(
            child: Text(
              'Pure State Debugger',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.delete, color: Colors.white70),
            onPressed: () => setState(() => _events.clear()),
          ),
          IconButton(
            icon: const Icon(Icons.close, color: Colors.white),
            onPressed: () => setState(() => _isOpen = false),
          ),
        ],
      ),
    );
  }

  Widget _buildEventItem(_DebugEvent event) {
    Color color;
    IconData icon;

    switch (event.type) {
      case _EventType.action:
        color = Colors.blueAccent;
        icon = Icons.bolt;
        break;
      case _EventType.error:
        color = Colors.redAccent;
        icon = Icons.error_outline;
        break;
    }

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      color: Colors.grey[800],
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 16, color: color),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    event.action,
                    style: TextStyle(
                      color: color,
                      fontWeight: FontWeight.bold,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Text(
                  _formatTime(event.timestamp),
                  style: const TextStyle(color: Colors.white54, fontSize: 12),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              'Store: ${event.store}',
              style: const TextStyle(color: Colors.white70, fontSize: 12),
            ),
            if (event.duration != null)
              Text(
                'Duration: ${event.duration!.inMilliseconds}ms',
                style: const TextStyle(color: Colors.greenAccent, fontSize: 12),
              ),
            if (event.error != null)
              Text(
                'Error: ${event.error}',
                style: const TextStyle(color: Colors.redAccent, fontSize: 12),
              ),
          ],
        ),
      ),
    );
  }
  
  String _formatTime(DateTime time) {
    return '${time.hour}:${time.minute}:${time.second}.${time.millisecond}';
  }
}

enum _EventType { action, error }

class _DebugEvent {
  final _EventType type;
  final DateTime timestamp;
  final String store;
  final String action;
  final Duration? duration;
  final String? error;

  _DebugEvent({
    required this.type,
    required this.timestamp,
    required this.store,
    required this.action,
    this.duration,
    this.error,
  });
}
