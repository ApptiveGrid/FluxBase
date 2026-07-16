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
	^ activation token scopeId
]

{ #category : 'as yet unclassified' }
FBNodeActivationEvent >> splitId [
	^ activation token splitId
]

{ #category : 'as yet unclassified' }
FBNodeActivationEvent >> tokenId [
	^ activation token id
]
