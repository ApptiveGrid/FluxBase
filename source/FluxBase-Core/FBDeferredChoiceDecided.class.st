"
I record that a deferred choice was decided (FBFlowInstance>>decideDeferredChoice:wonBy:):
one branch went on, the others fell. The strands taken back leave their own traces - an
FBNodeActivationCancelled per activation that stood.

	choiceName		the name of the FBDeferredChoice
	winnerTokenId	the first token of the winning branch, by id - the log is an
				outside-facing representation
"
Class {
	#name : 'FBDeferredChoiceDecided',
	#superclass : 'FBFlowInstanceEvent',
	#instVars : [
		'choiceName',
		'winnerTokenId'
	],
	#category : 'FluxBase-Core-Event',
	#package : 'FluxBase-Core',
	#tag : 'Event'
}

{ #category : 'accessing' }
FBDeferredChoiceDecided >> choice: aNode winner: aToken [
	choiceName := aNode name.
	winnerTokenId := aToken id
]

{ #category : 'accessing' }
FBDeferredChoiceDecided >> choiceName [
	^ choiceName
]

{ #category : 'printing' }
FBDeferredChoiceDecided >> message [
	^ 'deferred choice decided: ', choiceName asString
]

{ #category : 'printing' }
FBDeferredChoiceDecided >> printOn: aStream [
	super printOn: aStream.
	aStream << 'deferred choice decided ' << choiceName asString
]

{ #category : 'accessing' }
FBDeferredChoiceDecided >> type [
	^ #deferredChoiceDecided
]

{ #category : 'accessing' }
FBDeferredChoiceDecided >> winnerTokenId [
	^ winnerTokenId
]
