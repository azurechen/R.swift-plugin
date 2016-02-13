Auto Resource Plugin for Xcode
==============================

This Xcode Plugin make you access resources like colors, images or strings easier and more accurately. It provides functions like `Android Resource Manager` in Swift.

It generates references for colors, images and localizable strings <del>automatically</del>. (It will be supported in the next version)

Usage
-----

###Strings

Get strings by calling `getString(R.string.{string_name})`

```swift
let str: String = getString(R.string.hello_world)
```

Even use the abbreviated form

```swift
let str: String = getString(.hello_world)
```

If you have some localizable string files, the `str` will show the text in your language.

* `Base.lproj/Localizable.strings`

```
// titles
"title1" = "Title 1";
"title2" = "Title 2";

// hello world
"hello_world" = "Hello, world!";
```

* `es.lproj/Localizable.strings`

```
// titles
"title1" = "título 1";
"title2" = "título 2";

// hello world
"hello_world" = "Hola mundo!";
```			

###Images

Assume this is any `*.xcassets` folder

<img src="./screenshots/pic_assets.png" width = "640" alt="Image.xcassets" />

Get images by calling `getImage(R.string.{image_name})`

```swift
imageView.image = getImage(R.image.icon_play)
```

or

```swift
imageView.image = getImage(.icon_play)
```

###Colors

Create a `Color.strings` file first and define some colors you like. The hex code of colors should follow `#RRGGBB`, `#RGB`, `#AARRGGBB` and `#ARGB` rules.

* `Color.strings`

```
// colors
"dark_red"       = "#8B0000";
"popcorn_yellow" = "#FAA";
"lake_michigan"  = "#DE50A6C2";
"cat_eye"        = "#EBE5";
```

And get colors by calling `getColor(R.color.{color_name})`

```swift
view.backgroundColor = getColor(R.color.popcorn_yellow)
```

or

```swift
view.backgroundColor = getColor(.popcorn_yellow)
```

How to Install
--------------

<del>Install it via <a href="http://alcatraz.io/">Alcatraz</a></del> (Not yet)<br />
or

1. `Clone` this repository and `build` it.
2. `Restart` Xcode

or

1. Download and unzip a <a href="https://github.com/azurechen/AutoResource/releases">release</a> to `~/Library/Application Support/Developer/Shared/Xcode/Plug-ins`
2. `Restart` Xcode

After restarting Xcode, open any project and 

1. Click `Product` -> `AutoResource` -> `Sync`
2. If you don't use AutoResource in this project anymore, click `Product` -> `AutoResource` -> `Clean` 

