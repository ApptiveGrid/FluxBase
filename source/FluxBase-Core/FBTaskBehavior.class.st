Class {
	#name : 'FBTaskBehavior',
	#superclass : 'FBNodeBehavior',
	#category : 'FluxBase-Core-Behavior',
	#package : 'FluxBase-Core',
	#tag : 'Behavior'
}

{ #category : 'execution' }
FBTaskBehavior >> execute [
	"the node's produced value becomes the activation's result - two different things
	under two different names, see FBNode>>producedValue"
	activation value: self node producedValue.
	activation done.
	activation followAllOutgoing.

]
