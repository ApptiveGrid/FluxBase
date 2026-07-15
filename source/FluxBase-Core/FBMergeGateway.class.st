Class {
	#name : 'FBMergeGateway',
	#superclass : 'FBGateway',
	#category : 'FluxBase-Core-Model',
	#package : 'FluxBase-Core',
	#tag : 'Model'
}

{ #category : 'testing' }
FBMergeGateway class >> isAbstract [

	^ self == FBMergeGateway
]

{ #category : 'as yet unclassified' }
FBMergeGateway >> addOutgoing: aTransition [
	outgoing isEmpty
		ifFalse: [ FBCannotAddTransition signal: 'a merge gateway can only have 1 outgoing transition' ].
	super addOutgoing: aTransition
]
