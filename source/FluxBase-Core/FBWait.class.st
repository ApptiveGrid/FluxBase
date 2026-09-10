Class {
	#name : 'FBWait',
	#superclass : 'FBNode',
	#category : 'FluxBase-Core-Model',
	#package : 'FluxBase-Core',
	#tag : 'Model'
}

{ #category : 'testing' }
FBWait class >> isAbstract [

	^ self == FBWait
]

{ #category : 'testing' }
FBWait >> parksOnEntry [
	"a wait may park - a condition wait that finds its condition holding goes on at once
	instead, and decides a deferred choice as it does (FBWaitForConditionBehavior)"
	^ true
]
