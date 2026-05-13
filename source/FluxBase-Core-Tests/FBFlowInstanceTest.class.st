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
	self assert: flowInstance pending size equals: 1.
	self assert: flowInstance pending first class equals: FBStartEvent  

]

{ #category : 'tests' }
FBFlowInstanceTest >> testFlowAnnouncements [ 
	| flowInstance events |
	flowInstance := FBFlow simpleFlow newInstance.
	flowInstance initialValue: 7. 
	events := OrderedCollection new.
	flowInstance whenAnnounced: FBNodeActivationStarted  do: [ :e | events add: e ] for: self.
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
		whenAnnounced: FBFlowEvent do: [ :e | events add: e ] for: self .
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
		whenAnnounced: FBFlowEvent do: [ :e | events add: e ] for: self .
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
