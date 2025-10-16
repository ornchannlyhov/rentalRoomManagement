enum AsyncValueState { loading, error, success }

class AsyncValue<T> {
  final T? data;
  final Object? error;
  final AsyncValueState state;

  const AsyncValue._({this.data, this.error, required this.state});

  const factory AsyncValue.loading() = AsyncLoading<T>;
  const factory AsyncValue.success(T data) = AsyncSuccess<T>;
  const factory AsyncValue.error(Object error) = AsyncError<T>;

  bool get isLoading => state == AsyncValueState.loading;
  bool get hasData => state == AsyncValueState.success && data != null;
  bool get hasError => state == AsyncValueState.error;

  //Helper to handle states easily in UI
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
        return success(
            this.data as T); 
    }
  }
}

// Subclasses for type safety 
class AsyncLoading<T> extends AsyncValue<T> {
  const AsyncLoading() : super._(state: AsyncValueState.loading);
}

class AsyncSuccess<T> extends AsyncValue<T> {
  const AsyncSuccess(T data)
      : super._(data: data, state: AsyncValueState.success);
}

class AsyncError<T> extends AsyncValue<T> {
  const AsyncError(Object error)
      : super._(error: error, state: AsyncValueState.error);
}
