# Echo

## A flexible input accessory controller

A hassle free micro framework for laying out input accessory views. Setting a view as the responder’s `inputAccessoryView` has many problems, and results in hacks fragmented throughout your code base. Echo instead listens to keyboard event and determines where your input accessory should be laid out. You’re responsible for updating your UI, becuase you know it much better then we do.

## Installation

### Using Carthage:

```
github "mogstad/echo"
```

### Using CocoaPods:

_TODO_

### Using submodules:

Highly discourage using submodules and dynamic frameworks, as Xcode requires dynamic frameworks to have the same schemas in the dynamic frameworks as the parent project. 

## Usage

_TODO_

## Credit

Echo is heavly inspired by Slack’s [SlackTextViewController](slackhq/SlackTextViewController), it’s probably a better fit for many applications, but if you need full control or don’t need all its feature echo might be a good fit.
