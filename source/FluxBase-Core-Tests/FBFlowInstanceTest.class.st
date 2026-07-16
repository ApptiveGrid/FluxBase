Class {
	#name : 'FBFlowInstanceTest',
	#superclass : 'FBTest',
	#category : 'FluxBase-Core-Tests',
	#package : 'FluxBase-Core-Tests'
}

{ #category : 'tests' }
FBFlowInstanceTest >> testActivationsAreDone [
	| flowInstance |
	flowInstance := FBFlow simpleFlow newInstance.
	flowInstance initialValue: nil.
	self assert: (flowInstance activations allSatisfy: [ :each | each state = #isDone ])
]

{ #category : 'tests' }
FBFlowInstanceTest >> testActivationsWithGatewayAreDone [
	| flowInstance |
	flowInstance := FBFlow gatewayedFlow newInstance.
	flowInstance initialValue: 7.
	flowInstance execute.
	self assert: flowInstance state equals: #done.
	self assert: (flowInstance activations allSatisfy: [ :each | each state = #done ])
]

{ #category : 'tests' }
FBFlowInstanceTest >> testCompleted [
	| flowInstance |
	flowInstance := FBFlow simpleFlow newInstance.
	flowInstance initialValue: 7.
	flowInstance execute.
	self assert: flowInstance isDone.
	self assert: flowInstance atEnd equals: true
]

{ #category : 'tests' }
FBFlowInstanceTest >> testCreateFlowInstance [
	| flowInstance |
	flowInstance := FBFlow simpleFlow newInstance.
	flowInstance initializeExecutor.
	self assert: flowInstance pending size equals: 1.
	self assert: flowInstance pending first class equals: FBWorkItem.
	self assert: flowInstance pending first transition class equals: FBStartEvent
]

{ #category : 'tests' }
FBFlowInstanceTest >> testFlowAnnouncements [ 
	| flowInstance events |
	flowInstance := FBFlow simpleFlow newInstance.
	flowInstance initialValue: 7. 
	events := OrderedCollection new.
	flowInstance whenAnnounced: FBNodeActivationStarted  do: [ :e | events add: e ].
	flowInstance execute.
	self assert: events size equals: flowInstance flow nodes size 
]

{ #category : 'tests' }
FBFlowInstanceTest >> testFlowAnnouncementsWithError [
	| flowInstance events |
	flowInstance := FBFlow simpleFlowWithError newInstance.
	flowInstance initialValue: 7.
	events := OrderedCollection new.
	flowInstance 
		whenAnnounced: FBFlowEvent do: [ :e | events add: e ] .
	flowInstance execute.
	self assert: events last class equals: FBNodeActivationErrored.
	self assert: flowInstance activations last state equals: #error 
]

{ #category : 'tests' }
FBFlowInstanceTest >> testFlowAnnouncementsWithSystemError [
	| flowInstance events |
	flowInstance := FBFlow simpleFlowWithSystemError newInstance.
	events := OrderedCollection new.
	flowInstance 
		whenAnnounced: FBFlowEvent do: [ :e | events add: e ].
	flowInstance initialValue: 7.
	self 
		should: [ flowInstance execute ]
		raise: ZeroDivide.
	self assert: events size equals: 7 
]

{ #category : 'tests' }
FBFlowInstanceTest >> testInstanceStateCreated [
	| flowInstance |
	flowInstance := FBFlow simpleFlow newInstance.
	flowInstance initialValue: 7.
	self assert: flowInstance state equals: #created
]

{ #category : 'tests' }
FBFlowInstanceTest >> testInstanceStateDone [
	| flowInstance |
	flowInstance := FBFlow simpleFlow newInstance.
	flowInstance initialValue: 7.
	flowInstance execute.
	self assert: flowInstance state equals: #done
]

{ #category : 'tests' }
FBFlowInstanceTest >> testInstanceStateError [
	| flowInstance |
	flowInstance := FBFlow simpleFlowWithError newInstance.
	flowInstance initialValue: 7.
	flowInstance step; step.
	self assert: flowInstance state equals: #error
]

{ #category : 'tests' }
FBFlowInstanceTest >> testInstanceStateRunning [
	| flowInstance |
	flowInstance := FBFlow simpleFlow newInstance.
	flowInstance initialValue: 7.
	flowInstance step.
	self assert: flowInstance state equals: #running
]

{ #category : 'tests' }
FBFlowInstanceTest >> testInstanceStateWaiting [
	| flowInstance |
	flowInstance := FBFlow simpleWaitFlow newInstance.
	flowInstance initialValue: 6.
	flowInstance step; step.
	self assert: flowInstance state equals: #waiting
]

{ #category : 'tests' }
FBFlowInstanceTest >> testListActivationEvents [
	| flowInstance events |
	flowInstance := FBFlow simpleFlow newInstance.
	flowInstance initialValue: 7. 
	flowInstance execute.
	events := flowInstance eventsOfActivation: flowInstance activations second.
	self assert: events size equals: 2
]

{ #category : 'tests' }
FBFlowInstanceTest >> testListNodeEvents [
	| flowInstance events node |
	flowInstance := FBFlow simpleFlow newInstance.
	flowInstance initialValue: 7. 
	flowInstance execute.
	node := flowInstance flow nodes second.
	events := flowInstance eventsOfNode: node.
	self assert: events size equals: 2
]

{ #category : 'as yet unclassified' }
FBFlowInstanceTest >> testNodeActivationEventScopeIdAndSplitIdAreNilBeforePhase3Wiring [
	| flowInstance node event |
	flowInstance := FBFlow simpleFlow newInstance.
	flowInstance initialValue: 7.
	flowInstance execute.
	node := flowInstance flow nodes second.
	event := (flowInstance eventsOfNode: node) detect: [ :e | e isKindOf: FBNodeActivationDone ].
	self assert: event scopeId isNil.
	self assert: event splitId isNil
]

{ #category : 'as yet unclassified' }
FBFlowInstanceTest >> testNodeActivationEventsExposeTokenId [
	| flowInstance node events startedEvent doneEvent |
	flowInstance := FBFlow simpleFlow newInstance.
	flowInstance initialValue: 7.
	flowInstance execute.
	node := flowInstance flow nodes second.
	events := flowInstance eventsOfNode: node.
	startedEvent := events detect: [ :e | e isKindOf: FBNodeActivationStarted ].
	doneEvent := events detect: [ :e | e isKindOf: FBNodeActivationDone ].
	self assert: startedEvent tokenId notNil.
	self assert: startedEvent tokenId equals: doneEvent tokenId
]

{ #category : 'as yet unclassified' }
FBFlowInstanceTest >> testNodeActivationEventsForDifferentNodesHaveDifferentTokenIds [
	| flowInstance firstNode secondNode firstEvent secondEvent |
	flowInstance := FBFlow simpleFlow newInstance.
	flowInstance initialValue: 7.
	flowInstance execute.
	firstNode := flowInstance flow start.
	secondNode := flowInstance flow nodes second.
	firstEvent := (flowInstance eventsOfNode: firstNode) detect: [ :e | e isKindOf: FBNodeActivationDone ].
	secondEvent := (flowInstance eventsOfNode: secondNode) detect: [ :e | e isKindOf: FBNodeActivationDone ].
	self deny: firstEvent tokenId equals: secondEvent tokenId
]

{ #category : 'tests' }
FBFlowInstanceTest >> testResumeWaitingAtContinuesTheFlow [
	| flow instance waitNode |
	flow := FBFlow simpleWaitFlow.
	instance := flow newInstance.
	instance executeWith: 4.

	self deny: instance atEnd.
	self assert: instance suspended size equals: 1.
	waitNode := instance suspended first.

	instance resumeWaitingAt: waitNode with: 4.
	instance execute.

	self assert: instance atEnd.
	self assert: instance state equals: #done.
	self assert: instance suspended isEmpty
]

{ #category : 'tests' }
FBFlowInstanceTest >> testResumeWaitingAtRaisesWhenNodeIsNotWaiting [
	| flow instance |
	flow := FBFlow simpleFlow.
	instance := flow newInstance.
	instance executeWith: 7.

	self
		should: [ instance resumeWaitingAt: flow start with: nil ]
		raise: FBNodeNotWaiting
]

{ #category : 'tests' }
FBFlowInstanceTest >> testSimpleWaitCompletion [
	| instance |
	instance := FBFlow simpleWaitFlow newInstance. 
	instance initialValue: 3.
	instance execute.
	self assert: instance isDone
]

{ #category : 'tests' }
FBFlowInstanceTest >> testSimpleWaitSuspension [ 
	| instance |
	instance := FBFlow simpleWaitFlow newInstance. 
	instance initialValue: 2.
	instance execute.
	self deny: instance isDone
]

{ #category : 'tests' }
FBFlowInstanceTest >> testStepping [
	| flowInstance |
	flowInstance := FBFlow simpleFlow newInstance.
	flowInstance initialValue: 7.
	self assert: flowInstance nextNode class equals: FBStartEvent.
	flowInstance step.
	self assert: flowInstance nextNode class equals: FBTask.
	flowInstance step.
	self assert: flowInstance nextNode class equals: FBEndEvent.
	flowInstance step.
	self assert: flowInstance isDone.
	self assert: flowInstance atEnd equals: true
]
