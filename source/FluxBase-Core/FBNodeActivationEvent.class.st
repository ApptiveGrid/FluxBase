Class {
	#name : 'FBNodeActivationEvent',
	#superclass : 'FBFlowInstanceEvent',
	#instVars : [
		'activation'
	],
	#category : 'FluxBase-Core-Event',
	#package : 'FluxBase-Core',
	#tag : 'Event'
}

{ #category : 'accessing' }
FBNodeActivationEvent >> activation [

	^ activation
]

{ #category : 'accessing' }
FBNodeActivationEvent >> activation: anObject [

	activation := anObject
]

{ #category : 'printing' }
FBNodeActivationEvent >> printOn: aStream [ 
	super printOn: aStream.
	activation node printOn: aStream.
]

{ #category : 'as yet unclassified' }
FBNodeActivationEvent >> scopeId [
	"The event log is an outside-facing representation, so it reports the scope by id
	even though the token itself references the scope directly."
	^ activation token scope ifNotNil: [ :each | each id ]
]

{ #category : 'as yet unclassified' }
FBNodeActivationEvent >> splitId [
	^ activation token splitId
]

{ #category : 'as yet unclassified' }
FBNodeActivationEvent >> tokenId [
	^ activation token id
]
