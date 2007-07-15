class ThreadExtra {
	/**
		Exits the current thread.
	**/
        public static function exit() {
                thread_exit();
        }


	/**
		Thread is the same as another
	**/
	public static function equals(thread1 : ThreadExtra, thread2 : ThreadExtra) {
		return thread_equal(thread1.handle, thread2.handle);
	}


	static var thread_exit = neko.Lib.load("threadextra","thread_exit",0);
	static var thread_equal = neko.Lib.load("threadextra","thread_equal",2);
}
