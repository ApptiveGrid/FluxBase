"
I record that a strand of execution was cancelled: FBFlowInstance>>cancelStrand: took the
token I name and everything descending from it out of the instance's queues, waits and
addresses. One of me per cancellation, whatever the strand consisted of - queued work
that never became a step leaves no other trace than me. A standing activation whose
wait fell gets an FBNodeActivationCancelled of its own besides.

	tokenId	the token the cancellation was asked for, by id - the log is an
			outside-facing representation, see FBNodeActivationEvent>>tokenId
"
Class {
	#name : 'FBStrandCancelled',
	#superclass : 'FBFlowInstanceEvent',
	#instVars : [
		'tokenId'
	],
	#category : 'FluxBase-Core-Event',
	#package : 'FluxBase-Core',
	#tag : 'Event'
}

{ #category : 'printing' }
FBStrandCancelled >> message [
	^ 'strand cancelled: ', tokenId asString
]

{ #category : 'printing' }
FBStrandCancelled >> printOn: aStream [ 
	super printOn: aStream.
	aStream << 'strand cancelled ' << tokenId asString
]

{ #category : 'accessing' }
FBStrandCancelled >> token: aToken [
	tokenId := aToken id
]

{ #category : 'accessing' }
FBStrandCancelled >> tokenId [
	^ tokenId
]

{ #category : 'accessing' }
FBStrandCancelled >> type [
	^ #strandCancelled
]
