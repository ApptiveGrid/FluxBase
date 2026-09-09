"
The outcome that reaches an FBRemoteFlowTask when its #maxWait ran out: whoever fires the
deadline - a schedule in the environment - signals me on the wait's correlationId, and
the task takes its #timedOut transition. See FBRemoteFlowOutcome.
"
Class {
	#name : 'FBRemoteFlowTimedOut',
	#superclass : 'FBRemoteFlowOutcome',
	#category : 'FluxBase-Core-Model',
	#package : 'FluxBase-Core',
	#tag : 'Model'
}

{ #category : 'accessing' }
FBRemoteFlowTimedOut >> description [
	^ 'remote flow timed out'
]

{ #category : 'accessing' }
FBRemoteFlowTimedOut >> resultName [
	^ #timedOut
]
