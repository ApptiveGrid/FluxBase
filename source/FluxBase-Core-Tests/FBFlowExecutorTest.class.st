Class {
	#name : 'FBFlowExecutorTest',
	#superclass : 'FBTest',
	#category : 'FluxBase-Core-Tests',
	#package : 'FluxBase-Core-Tests'
}

{ #category : 'as yet unclassified' }
FBFlowExecutorTest >> testActivationBeforeReturnsThePreviouslyCreatedActivation [
	| instance task end taskActivation endActivation |
	instance := FBFlow simpleFlow newInstance.
	instance executeWith: 7.
	task := instance flow nodes second.
	end := instance flow end.
	taskActivation := instance executor activationOf: task.
	endActivation := instance executor activationOf: end.
	self assert: (instance executor activationBefore: endActivation) equals: taskActivation
]

{ #category : 'as yet unclassified' }
FBFlowExecutorTest >> testActivationOfReturnsTheActivationForThatNode [
	| instance task activation |
	instance := FBFlow simpleFlow newInstance.
	instance executeWith: 7.
	task := instance flow nodes second.
	activation := instance executor activationOf: task.
	self assert: activation node equals: task
]

{ #category : 'as yet unclassified' }
FBFlowExecutorTest >> testAddWaitingAddsNodeToSuspended [
	| instance waitNode |
	instance := FBFlow simpleWaitFlow newInstance.
	instance executeWith: 4.
	waitNode := instance suspended first.
	self assert: (instance executor suspended includes: waitNode)
]

{ #category : 'as yet unclassified' }
FBFlowExecutorTest >> testExecuteRunsUntilPendingIsEmptyAndReachesEnd [
	| instance |
	instance := FBFlow simpleFlow newInstance.
	instance executeWith: 7.
	self assert: instance atEnd.
	self assert: instance pending isEmpty
]

{ #category : 'as yet unclassified' }
FBFlowExecutorTest >> testFirstStepActivatesStartNodeUsingItselfAsPseudoTransition [
	| instance |
	instance := FBFlow simpleFlow newInstance.
	instance initializeExecutor.
	instance step.
	self assert: (instance activationOfNode: instance start) notNil.
	self deny: instance pending first equals: instance start
]

{ #category : 'as yet unclassified' }
FBFlowExecutorTest >> testHasPendingReflectsPendingState [
	| instance |
	instance := FBFlow simpleFlow newInstance.
	instance initializeExecutor.
	self assert: instance executor hasPending.
	instance execute.
	self deny: instance executor hasPending
]

{ #category : 'as yet unclassified' }
FBFlowExecutorTest >> testIsDoneFalseWhilePendingOrSuspendedAreNotEmpty [
	| instance |
	instance := FBFlow simpleWaitFlow newInstance.
	instance executeWith: 4.
	self deny: instance executor isDone.
	self assert: instance pending isEmpty.
	self deny: instance suspended isEmpty
]

{ #category : 'as yet unclassified' }
FBFlowExecutorTest >> testIsWaitingTrueOnlyWhenPendingEmptyAndSuspendedNotEmpty [
	| instance |
	instance := FBFlow simpleWaitFlow newInstance.
	instance executeWith: 4.
	self assert: instance executor isWaiting
]

{ #category : 'as yet unclassified' }
FBFlowExecutorTest >> testLastValueOfReturnsTheActivationsValue [
	| instance task |
	instance := FBFlow simpleFlow newInstance.
	instance executeWith: 7.
	task := instance flow nodes second.
	self assert: (instance executor lastValueOf: task) equals: ((instance executor activationOf: task) value)
]

{ #category : 'as yet unclassified' }
FBFlowExecutorTest >> testResumeWaitingRemovesNodeFromSuspendedAndReachesEnd [
	| instance waitNode |
	instance := FBFlow simpleWaitFlow newInstance.
	instance executeWith: 4.
	waitNode := instance suspended first.
	instance resumeWaitingAt: waitNode with: 5.
	instance execute.
	self assert: instance atEnd.
	self assert: instance suspended isEmpty
]

{ #category : 'as yet unclassified' }
FBFlowExecutorTest >> testScheduleStartAddsFlowInstanceStartedEvent [
	| instance |
	instance := FBFlow simpleFlow newInstance.
	instance initializeExecutor.
	self assert: (instance events anySatisfy: [ :e | e isKindOf: FBFlowInstanceStarted ])
]

{ #category : 'as yet unclassified' }
FBFlowExecutorTest >> testScheduleStartAddsStartNodeAsPendingAndMarksCreated [
	| instance |
	instance := FBFlow simpleFlow newInstance.
	instance initializeExecutor.
	self assert: instance pending size equals: 1.
	self assert: instance pending first equals: instance start.
	self assert: instance executor isCreated
]

{ #category : 'as yet unclassified' }
FBFlowExecutorTest >> testStepConsumesPendingOneAtATimeOnALinearFlow [
	| instance |
	instance := FBFlow simpleFlow newInstance.
	instance initializeExecutor.
	self assert: instance pending size equals: 1.
	instance step.
	self assert: instance pending size equals: 1.
	instance step.
	self assert: instance pending size equals: 1.
	instance step.
	self assert: instance pending isEmpty
]
