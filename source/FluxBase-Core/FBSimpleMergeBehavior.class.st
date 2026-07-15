Class {
	#name : 'FBSimpleMergeBehavior',
	#superclass : 'FBNodeBehavior',
	#category : 'FluxBase-Core-Behavior',
	#package : 'FluxBase-Core',
	#tag : 'Behavior'
}

{ #category : 'execution' }
FBSimpleMergeBehavior >> execute [
	activation value: self argument.
	activation done.
	activation followAllOutgoing.
]
