"
I am what reaches an FBRemoteFlowTask in place of a result when the remote flow did not
succeed: a timeout (FBRemoteFlowTimedOut) or a failure the other side reported
(FBRemoteFlowFailed). Whoever knows the outcome signals me on the wait's correlationId,
and the task takes the transition I name - #timedOut or #error - or stops in error when
that transition is not modelled (FBRemoteFlowTask>>resumeIn:withToken:value:). A result
arriving after me finds the address consumed and is silent, and so am I after a result.

	resultName	the transition I take, see FBNode>>resultTransition:
	description	what to record on the activation when that transition is missing
"
Class {
	#name : 'FBRemoteFlowOutcome',
	#superclass : 'Object',
	#category : 'FluxBase-Core-Model',
	#package : 'FluxBase-Core',
	#tag : 'Model'
}

{ #category : 'testing' }
FBRemoteFlowOutcome class >> isAbstract [
	^ self == FBRemoteFlowOutcome
]

{ #category : 'accessing' }
FBRemoteFlowOutcome >> description [
	^ self subclassResponsibility
]

{ #category : 'printing' }
FBRemoteFlowOutcome >> printOn: aStream [
	aStream << self description
]

{ #category : 'accessing' }
FBRemoteFlowOutcome >> resultName [
	^ self subclassResponsibility
]
