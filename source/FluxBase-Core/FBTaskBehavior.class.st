Class {
	#name : 'FBTaskBehavior',
	#superclass : 'FBNodeBehavior',
	#category : 'FluxBase-Core-Behavior',
	#package : 'FluxBase-Core',
	#tag : 'Behavior'
}

{ #category : 'execution' }
FBTaskBehavior >> execute [ 
	activation value: self node value.
	activation done.
	activation followAllOutgoing.

]
