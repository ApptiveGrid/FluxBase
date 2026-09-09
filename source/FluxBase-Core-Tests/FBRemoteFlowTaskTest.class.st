"
An FBRemoteFlowTask without a transport: what goes out through the port, what comes back
through FBFlowInstance>>signal:with:, and which way the task goes on. The port is an
FBPluggableDispatchPort recording its calls; the callback is played by hand.
"
Class {
	#name : 'FBRemoteFlowTaskTest',
	#superclass : 'FBTest',
	#instVars : [
		'calls'
	],
	#category : 'FluxBase-Core-Tests',
	#package : 'FluxBase-Core-Tests'
}

{ #category : 'private' }
FBRemoteFlowTaskTest >> linkNodeReservingAt: aNode [
	"stands in for a link node ahead of the remote task - an address handed out before
	the task runs, the mail case of FBWaitingRegistryTest"
	^ (FBPluggableTask named: 'link') block: [ :act |
		act flowInstance reserveWaitingSpotAt: aNode anchoredAt: act token.
		act value: act argument ]
]

{ #category : 'private' }
FBRemoteFlowTaskTest >> port [
	"a port on a machine whose locator carries colons of its own, as a URL does"
	^ FBPluggableDispatchPort new
		locator: 'https://grid.example:8443/api/a/owner/hook';
		onDispatch: [ :call | calls add: call ];
		yourself
]

{ #category : 'private' }
FBRemoteFlowTaskTest >> remoteTask [
	^ (FBRemoteFlowTask named: 'approval')
		targetFlowName: 'approve-order';
		dispatchPort: self port;
		yourself
]

{ #category : 'running' }
FBRemoteFlowTaskTest >> setUp [
	super setUp.
	calls := OrderedCollection new
]

{ #category : 'tests' }
FBRemoteFlowTaskTest >> testAFailureTakesTheErrorTransition [
	"the other side reports that its flow stopped in error. The report is an
	FBRemoteFlowFailed on the same address, and the task takes its #error branch - the
	branch a local sub flow call takes when its child errors. A result arriving afterwards
	finds the address consumed"
	| start task onSuccess onError flow instance correlationId |
	start := FBStartEvent new.
	task := self remoteTask.
	onSuccess := FBEndEvent new.
	onError := FBEndEvent new.
	start --> task.
	task --> (onSuccess resultTransition: #success).
	task --> (onError resultTransition: #error).
	flow := FBFlow new start: start.
	instance := flow newInstance.
	instance executeWith: 1.
	correlationId := calls first correlationId.

	self assert: (instance signal: correlationId with: (FBRemoteFlowFailed reason: 'no stock')).
	instance execute.
	self deny: (instance signal: correlationId with: #tooLate).

	self assert: instance state equals: #done.
	self assert: (instance rootExecutor activationOf: onError) node equals: onError.
	self should: [ instance rootExecutor activationOf: onSuccess ] raise: Error
]

{ #category : 'tests' }
FBRemoteFlowTaskTest >> testAFailureWithoutAnErrorTransitionStopsTheInstanceInError [
	"no #error branch modelled: the task stops in error with the other side's reason on
	record, the way it stops on a timeout without a #timedOut branch"
	| start task end flow instance errored |
	start := FBStartEvent new.
	task := self remoteTask.
	end := FBEndEvent new.
	start --> task --> end.
	flow := FBFlow new start: start.
	instance := flow newInstance.
	instance executeWith: 1.

	self assert: (instance signal: calls first correlationId with: (FBRemoteFlowFailed reason: 'no stock')).
	instance execute.

	self assert: instance state equals: #error.
	errored := instance events last.
	self assert: (errored isKindOf: FBNodeActivationErrored).
	self assert: (errored message includesSubstring: 'no stock').
	self assert: (errored message includesSubstring: '#error').
	self should: [ instance rootExecutor activationOf: end ] raise: Error
]

{ #category : 'tests' }
FBRemoteFlowTaskTest >> testTheInputIsWhatTheTaskAnswersForTheActivation [
	"the remote flow's input is #inputValueFor: - the argument by default, and whatever a
	subclass assembles otherwise. A task standing in for such a subclass here"
	| start task end flow instance |
	start := FBStartEvent new.
	task := FBRemoteFlowTaskAssemblingItsInput new
		name: 'assembling';
		targetFlowName: 'approve-order';
		dispatchPort: self port;
		yourself.
	end := FBEndEvent new.
	start --> task --> end.
	flow := FBFlow new start: start.
	instance := flow newInstance.
	instance executeWith: 5.

	self assert: calls first inputValue equals: { #amount -> 5. #currency -> 'EUR' } asDictionary.
	self assert: calls first flowInstance identicalTo: instance
]

{ #category : 'tests' }
FBRemoteFlowTaskTest >> testAResultTakesTheSuccessTransition [
	| start task onSuccess onTimeout flow instance |
	start := FBStartEvent new.
	task := self remoteTask.
	onSuccess := FBEndEvent new.
	onTimeout := FBEndEvent new.
	start --> task.
	task --> (onSuccess resultTransition: #success).
	task --> (onTimeout resultTransition: #timedOut).
	flow := FBFlow new start: start.
	instance := flow newInstance.
	instance executeWith: 1.

	self assert: (instance signal: calls first correlationId with: #approved).
	instance execute.

	self assert: instance state equals: #done.
	self assert: (instance rootExecutor activationOf: onSuccess) argument equals: #approved.
	self should: [ instance rootExecutor activationOf: onTimeout ] raise: Error
]

{ #category : 'tests' }
FBRemoteFlowTaskTest >> testASecondSignalOnTheAddressIsSilent [
	"the registry's promise, measured on the remote task: a callback delivered twice - a
	retry on the other side - changes nothing the second time"
	| start task end flow instance correlationId |
	start := FBStartEvent new.
	task := self remoteTask.
	end := FBEndEvent new.
	start --> task --> end.
	flow := FBFlow new start: start.
	instance := flow newInstance.
	instance executeWith: 1.
	correlationId := calls first correlationId.

	self assert: (instance signal: correlationId with: 42).
	instance execute.
	self deny: (instance signal: correlationId with: 43).

	self assert: instance state equals: #done.
	self assert: (instance activations select: [ :each | each node == end ]) size equals: 1.
	self assert: (instance rootExecutor activationOf: end) argument equals: 42
]

{ #category : 'tests' }
FBRemoteFlowTaskTest >> testASignalOnTheCallbackAddressResumesWithTheResult [
	"the whole round trip without a wire: the other side parses the callback address it
	was given, and comes back with the correlationId in it and a result. The task goes
	on with that result as its value"
	| start task end flow instance parsed |
	start := FBStartEvent new.
	task := self remoteTask.
	end := FBEndEvent new.
	start --> task --> end.
	flow := FBFlow new start: start.
	instance := flow newInstance.
	instance executeWith: 5.

	parsed := FBCallbackAddress fromString: calls first callbackAddress asString.
	self assert: (instance signal: parsed correlationId with: 42).
	instance execute.

	self assert: instance state equals: #done.
	self assert: (instance activations detect: [ :each | each node == task ]) value equals: 42.
	self assert: (instance rootExecutor activationOf: end) argument equals: 42.
	self assert: instance openWaitingEntries isEmpty
]

{ #category : 'tests' }
FBRemoteFlowTaskTest >> testAStringThatIsNoCallbackAddressIsRejected [
	self should: [ FBCallbackAddress fromString: 'https://elsewhere/callback/abc' ] raise: FBError.
	self should: [ FBCallbackAddress fromString: 'urn:fluxbase:instance:onlyone' ] raise: FBError.
	self should: [ FBCallbackAddress fromString: 'urn:fluxbase:instance:host:' ] raise: FBError
]

{ #category : 'tests' }
FBRemoteFlowTaskTest >> testATimeoutTakesTheTimedOutTransition [
	"the deadline fired instead of the callback: whoever fires it signals an
	FBRemoteFlowTimedOut on the same address, and the task takes its #timedOut branch.
	A callback arriving afterwards finds the address consumed"
	| start task onSuccess onTimeout flow instance correlationId |
	start := FBStartEvent new.
	task := self remoteTask.
	onSuccess := FBEndEvent new.
	onTimeout := FBEndEvent new.
	start --> task.
	task --> (onSuccess resultTransition: #success).
	task --> (onTimeout resultTransition: #timedOut).
	flow := FBFlow new start: start.
	instance := flow newInstance.
	instance executeWith: 1.
	correlationId := calls first correlationId.

	self assert: (instance signal: correlationId with: FBRemoteFlowTimedOut new).
	instance execute.
	self deny: (instance signal: correlationId with: #tooLate).

	self assert: instance state equals: #done.
	self assert: (instance rootExecutor activationOf: onTimeout) node equals: onTimeout.
	self should: [ instance rootExecutor activationOf: onSuccess ] raise: Error
]

{ #category : 'tests' }
FBRemoteFlowTaskTest >> testATimeoutWithoutATimedOutTransitionStopsTheInstanceInError [
	"no #timedOut branch modelled: the task stops in error, recorded on its activation,
	the way a sub flow call without an #error transition does - not signalled, since the
	impulse comes from outside the activation's protected block"
	| start task end flow instance |
	start := FBStartEvent new.
	task := self remoteTask.
	end := FBEndEvent new.
	start --> task --> end.
	flow := FBFlow new start: start.
	instance := flow newInstance.
	instance executeWith: 1.

	self assert: (instance signal: calls first correlationId with: FBRemoteFlowTimedOut new).
	instance execute.

	self assert: instance state equals: #error.
	self assert: (instance activations detect: [ :each | each node == task ]) hasError.
	self assert: (instance events last isKindOf: FBNodeActivationErrored).
	self should: [ instance rootExecutor activationOf: end ] raise: Error
]

{ #category : 'tests' }
FBRemoteFlowTaskTest >> testDispatchParksTheTaskAndHandsThePortItsAddress [
	"running the task sends exactly one call and leaves the instance waiting. The call
	carries the task's argument as the remote flow's input, the target's name, and the
	address of the wait - the same correlationId the registry holds, wrapped with the
	port's locator into the callback address"
	| start task end flow instance call |
	start := FBStartEvent new.
	task := self remoteTask.
	end := FBEndEvent new.
	start --> task --> end.
	flow := FBFlow new start: start.
	instance := flow newInstance.
	instance executeWith: 5.

	self assert: instance state equals: #waiting.
	self assert: instance suspended asArray equals: { task }.
	self assert: calls size equals: 1.
	call := calls first.
	self assert: call inputValue equals: 5.
	self assert: call targetFlowName equals: 'approve-order'.
	self assert: call dispatchedAt notNil.
	self assert: instance openWaitingEntries size equals: 1.
	self assert: call correlationId equals: instance openWaitingEntries first correlationId.
	self assert: call callbackAddress correlationId equals: call correlationId.
	self assert: call callbackAddress locator equals: 'https://grid.example:8443/api/a/owner/hook'
]

{ #category : 'tests' }
FBRemoteFlowTaskTest >> testTheAddressHandedToThePortIsTheOneReservedAhead [
	"an address handed out before the task ran - a link node ahead of it - is the task's
	address: the parking mints no second one, and the port gets the reserved one, so
	that whatever was told the address earlier and the remote flow agree"
	| start link task end flow instance |
	start := FBStartEvent new.
	task := self remoteTask.
	link := self linkNodeReservingAt: task.
	end := FBEndEvent new.
	start --> link --> task --> end.
	flow := FBFlow new start: start.
	instance := flow newInstance.
	instance executeWith: 1.

	self assert: instance openWaitingEntries size equals: 1.
	self assert: (instance openWaitingEntries first isKindOf: FBWaitingReservation).
	self assert: calls first correlationId equals: instance openWaitingEntries first correlationId.

	self assert: (instance signal: calls first correlationId with: 9).
	instance execute.
	self assert: instance state equals: #done.
	self assert: (instance rootExecutor activationOf: end) argument equals: 9
]

{ #category : 'tests' }
FBRemoteFlowTaskTest >> testTheCallbackAddressRoundTripsWithALocatorThatHasColons [
	| address parsed |
	address := FBCallbackAddress locator: 'https://grid.example:8443/api/a/owner/hook' correlationId: 'abc123'.
	self assert: address asString equals: 'urn:fluxbase:instance:https://grid.example:8443/api/a/owner/hook:abc123'.
	parsed := FBCallbackAddress fromString: address asString.
	self assert: parsed locator equals: 'https://grid.example:8443/api/a/owner/hook'.
	self assert: parsed correlationId equals: 'abc123'.
	self assert: parsed equals: address
]
