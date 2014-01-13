MoviePlayerFullscreenOverlay
============================

If you want add an overlay view to the MPMoviePlayerController fullscreen view you have three options:

1. Don't.
2. Write your own MoviePlayer based on AVPlayer.
3. Use the *hack* shown in this repository.

Adding an overlay view to the MPMoviePlayerController is not straightforward because the fullscreen view is not accessible from the MPMoviePlayerController API. It requires accessing the view through the window, adding the subview and then manually handling the rotation callbacks. Pain in the $%^*.

Please do not use this approach for any other situation.

If you want to add an overlay view to the MPMoviePlayerController non-fullscreen view see Apple's [Movie Player](https://developer.apple.com/library/ios/samplecode/MoviePlayer_iPhone/Introduction/Intro.html) sample code. Be aware that Apple's sample has not been updated beyond iOS4 and has issues on iOS6+. It needs a fullscreen check added to <code>viewWillAppear:</code> and <code>viewDidDisappear:</code> as shown in this repository.
