// This THREEx helper makes it easy to handle window resize.
// It will update renderer and camera when window is resized.
//
// # Usage
//
// **Step 1**: Start updating renderer and camera
//
// ```var windowResize = THREEx.WindowResize(aRenderer, aCamera)```
//    
// **Step 2**: Start updating renderer and camera
//
// ```windowResize.stop()```
// # Code

// modified to introduce padding variable
//   -mmorsi

//

/** @namespace */
var THREEx	= THREEx 		|| {};

/**
 * Update renderer and camera when the window is resized
 * 
 * @param {Object} renderer the renderer to update
 * @param {Object} Camera the camera to update
*/
THREEx.WindowResize	= function(renderer, camera, padding){
  if(padding == null || typeof(padding) === 'undefined') padding = 0;

	var callback	= function(){
    var width  = window.innerWidth  - padding;
    var height = window.innerHeight - padding;

		// notify the renderer of the size change
		renderer.setSize(width, height);
		// update the camera
		camera.aspect	= width / height;
		camera.updateProjectionMatrix();
    // TODO animate scene
	}
	// bind the resize event
	window.addEventListener('resize', callback, false);
	// return .stop() the function to stop watching window resize
	return {
		/**
		 * Stop watching window resize
		*/
		stop	: function(){
			window.removeEventListener('resize', callback);
		}
	};
}
