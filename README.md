HandwritingTextField
====================

This library provides a category for UITextField category to supporting handwriting input.

It provides:
- An UITextField category adding touch tracking and handwriting recognition
- Handwriting view property for tracking and handwriting recognition results
- Custom controls
- Asynchronous recognition via google
- TrackingViewDelegate allows for easy customization and filtering
- Uses GCD and ARC
- Uses NSURLSession, so iOS >= 7.0
- Demo projects for iPhone and iPad


Screenshots
-----------

![Custom view](/screenshots/custom_view.png?raw=true)


What's Included
---------------
HandwritingTextField folder - UITextField category
HandwritingTextFieldDemo - demo project


How To Use
----------

There are two ways to use this in your project: copy the HandwritingTextField folder into your project, or use the demo project as a starting point

### Import headers in your source files

In the source files where you need to use the library, import the header file:

```objective-c
#import "UITextField+Handwriting.h"
```

### Setup the handwriting view and you are ready to go
```objective-c
[textField setHandwritingView:[self view]];
[textField beginHandwriting];
```
