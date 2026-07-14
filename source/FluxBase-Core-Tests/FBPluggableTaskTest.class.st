Class {
	#name : 'FBPluggableTaskTest',
	#superclass : 'FBTest',
	#category : 'FluxBase-Core-Tests',
	#package : 'FluxBase-Core-Tests'
}

{ #category : 'tests' }
FBPluggableTaskTest >> testActivationIsDoneAfterExecute [
	| start task end flow instance activation |
	start := FBStartEvent new.
	task := (FBPluggableTask named: 'pluggable') value: 42.
	end := FBEndEvent new.

	start --> task --> end.

	flow := FBFlow new start: start.
	instance := flow newInstance.
	instance executeWith: nil.

	self assert: instance atEnd.
	self assert: instance state equals: #done.
	activation := instance activationOfNode: task.
	self assert: activation isDone.
	self assert: activation value equals: 42
]
