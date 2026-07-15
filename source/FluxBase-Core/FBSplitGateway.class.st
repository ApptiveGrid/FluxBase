Class {
	#name : 'FBSplitGateway',
	#superclass : 'FBGateway',
	#category : 'FluxBase-Core-Model',
	#package : 'FluxBase-Core',
	#tag : 'Model'
}

{ #category : 'testing' }
FBSplitGateway class >> isAbstract [

	^ self == FBSplitGateway
]

{ #category : 'as yet unclassified' }
FBSplitGateway >> addIncoming: aTransition [
	incoming isEmpty
		ifFalse: [ FBCannotAddTransition signal: 'a split gateway can only have 1 incoming transition' ].
	super addIncoming: aTransition
]
