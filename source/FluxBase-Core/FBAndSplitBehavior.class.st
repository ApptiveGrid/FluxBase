Class {
	#name : 'FBAndSplitBehavior',
	#superclass : 'FBNodeBehavior',
	#category : 'FluxBase-Core-Behavior',
	#package : 'FluxBase-Core',
	#tag : 'Behavior'
}

{ #category : 'execution' }
FBAndSplitBehavior >> execute [
	activation value: self argument.
	activation done.
	activation followAllOutgoing.
]
