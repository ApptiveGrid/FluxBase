Class {
	#name : 'FBMultiChoiceGatewayBehavior',
	#superclass : 'FBNodeBehavior',
	#category : 'FluxBase-Core-Behavior',
	#package : 'FluxBase-Core',
	#tag : 'Behavior'
}

{ #category : 'execution' }
FBMultiChoiceGatewayBehavior >> execute [
	activation value: self argument.
	activation done.
	activation followAllOutgoing.

]
