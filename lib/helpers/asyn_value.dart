enum AsyncValueState { loading, error, success }

class AsyncValue<T> {
  final T? data;
  final Object? error;
  final AsyncValueState state;
  final T? previousData; // Keep previous data during transitions

  const AsyncValue._({
    this.data,
    this.error,
    required this.state,
    this.previousData,
  });

  const factory AsyncValue.loading([T? previousData]) = AsyncLoading<T>;
  const factory AsyncValue.success(T data) = AsyncSuccess<T>;
  const factory AsyncValue.error(Object error, [T? previousData]) =
      AsyncError<T>;

  bool get isLoading => state == AsyncValueState.loading;
  bool get hasData => state == AsyncValueState.success && data != null;
  bool get hasError => state == AsyncValueState.error;

  /// Check if we have any data (current or previous)
  bool get hasAnyData => data != null || previousData != null;

  /// Get the best available data (current or fall back to previous)
  T? get bestData => data ?? previousData;

  /// Helper to handle states easily in UI
  W when<W>({
    required W Function() loading,
    required W Function(Object error) error,
    required W Function(T data) success,
  }) {
    switch (state) {
      case AsyncValueState.loading:
        return loading();
      case AsyncValueState.error:
        return error(this.error!);
      case AsyncValueState.success:
        return success(this.data as T);
    }
  }

  /// NEW: Enhanced when that provides previous data during loading/error
  W whenWithPrevious<W>({
    required W Function(T? previousData) loading,
    required W Function(Object error, T? previousData) error,
    required W Function(T data) success,
  }) {
    switch (state) {
      case AsyncValueState.loading:
        return loading(previousData);
      case AsyncValueState.error:
        return error(this.error!, previousData);
      case AsyncValueState.success:
        return success(this.data as T);
    }
  }

  /// NEW: Map data while preserving state
  AsyncValue<R> map<R>(R Function(T data) transform) {
    switch (state) {
      case AsyncValueState.loading:
        return AsyncValue.loading(
          previousData != null ? transform(previousData as T) : null,
        );
      case AsyncValueState.error:
        return AsyncValue.error(
          error!,
          previousData != null ? transform(previousData as T) : null,
        );
      case AsyncValueState.success:
        return AsyncValue.success(transform(data as T));
    }
  }
}

// Subclasses for type safety
class AsyncLoading<T> extends AsyncValue<T> {
  const AsyncLoading([T? previousData])
      : super._(
          state: AsyncValueState.loading,
          previousData: previousData,
        );
}

class AsyncSuccess<T> extends AsyncValue<T> {
  const AsyncSuccess(T data)
      : super._(data: data, state: AsyncValueState.success);
}

class AsyncError<T> extends AsyncValue<T> {
  const AsyncError(Object error, [T? previousData])
      : super._(
          error: error,
          state: AsyncValueState.error,
          previousData: previousData,
        );
}
