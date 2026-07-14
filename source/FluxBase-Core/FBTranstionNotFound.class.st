Class {
	#name : 'FBTranstionNotFound',
	#superclass : 'FBTransitionNotFound',
	#category : 'FluxBase-Core-Error',
	#package : 'FluxBase-Core',
	#tag : 'Error'
}

{ #category : 'instance creation' }
FBTranstionNotFound class >> new [
	self deprecated: 'FBTranstionNotFound is misspelled and deprecated, use FBTransitionNotFound instead'.
	^ super new
]
