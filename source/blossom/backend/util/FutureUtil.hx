package blossom.backend.util;

import lime.app.Future;
import lime.app.Promise;

final class FutureUtil {
	public static function chainFutures<U>(futures:Array<Future<T>>, ?next:Array<Future<T>>->Future<U>):Future<U> {
		if (futures == null || futures.length == 0) return next != null ? next(null) : Future.withValue(null);

		final promise = new Promise<U>();
		var progress:Int = 0;

		function onComplete(value:T) {
			if (++progress >= futures.length) {
				final future = next(futures);
				future.onError(promise.error);
				future.onComplete(promise.complete);
			}
			else
				promise.progress(progress, futures.length);
		}

		for (future in futures) future.onError(promise.error).onComplete(value);
		return promise.future;
	}

	public static function waitTime<T>(future:Future<T>, waitTime = 8):Future<T> {
		if (future.isComplete) return future;

		

		return future;
	}
}