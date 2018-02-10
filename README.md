# wekinatorControllerIOS

iOS controller for use with Rebecca Fiebrink's http://wekinator.org/

Controls for recording, training, and running and deleting training examples. 

Enter host ip and port in the text boxes.

Will pass osc messages for:

* accelerometer(x,y,z) 
* moving rotation(x,y,z)
* attitude(roll,pitch,yaw)
* magnetic heading 

as 10 seperate features.

TODO:
* add touch events, sliders, button etc...

-- REQUIRES SwiftOSC


![](https://raw.githubusercontent.com/isaac-art/wekinatorControllerIOS/master/screenshot.jpg)
![](https://raw.githubusercontent.com/isaac-art/wekinatorControllerIOS/master/dataPlotterExample.png)
