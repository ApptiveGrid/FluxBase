"
The outcome that reaches an FBRemoteFlowTask when the other side reports that its flow
stopped in error: the remote instance does not end, it stops, so the report comes from
whoever notices the stop there, not from the instance's end. The task takes its #error
transition - the same branch a local FBSubFlowNode takes when its child errors. Without
me a caller would wait for a result that never comes, until a timeout that may not be
modelled either. See FBRemoteFlowOutcome.

	reason	what the other side said went wrong, for the activation's error record
"
Class {
	#name : 'FBRemoteFlowFailed',
	#superclass : 'FBRemoteFlowOutcome',
	#instVars : [
		'reason'
	],
	#category : 'FluxBase-Core-Model',
	#package : 'FluxBase-Core',
	#tag : 'Model'
}

{ #category : 'instance creation' }
FBRemoteFlowFailed class >> reason: aString [
	^ self new
		reason: aString;
		yourself
]

{ #category : 'accessing' }
FBRemoteFlowFailed >> description [
	^ 'remote flow failed', (reason ifNil: [ '' ] ifNotNil: [ :text | ': ', text asString ])
]

{ #category : 'accessing' }
FBRemoteFlowFailed >> reason [
	^ reason
]

{ #category : 'accessing' }
FBRemoteFlowFailed >> reason: aString [
	reason := aString
]

{ #category : 'accessing' }
FBRemoteFlowFailed >> resultName [
	^ #error
]
