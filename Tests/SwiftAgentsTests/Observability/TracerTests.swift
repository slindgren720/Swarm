// TracerTests.swift
// SwiftAgents Framework
//
// Comprehensive tests for tracer types from AgentTracer.swift

import Foundation
import Testing
@testable import SwiftAgents

// MARK: - Test Spy Tracer

/// Spy tracer that records all traced events for verification.
actor SpyTracer: AgentTracer {
    private(set) var tracedEvents: [TraceEvent] = []
    private(set) var flushCallCount: Int = 0
    private(set) var traceCallCount: Int = 0
    
    func trace(_ event: TraceEvent) async {
        tracedEvents.append(event)
        traceCallCount += 1
    }
    
    func flush() async {
        flushCallCount += 1
    }
    
    /// Reset the spy to initial state
    func reset() {
        tracedEvents.removeAll()
        flushCallCount = 0
        traceCallCount = 0
    }
    
    /// Check if a specific event was traced
    func wasTraced(eventWithKind kind: EventKind) -> Bool {
        tracedEvents.contains { $0.kind == kind }
    }
    
    /// Get events matching a specific level
    func events(withLevel level: EventLevel) -> [TraceEvent] {
        tracedEvents.filter { $0.level == level }
    }
}

// MARK: - CompositeTracer Tests

@Suite("CompositeTracer Tests")
struct CompositeTracerTests {
    
    @Test("CompositeTracer initializes with multiple tracers")
    func initializesWithMultipleTracers() async {
        // Given
        let spy1 = SpyTracer()
        let spy2 = SpyTracer()
        let spy3 = SpyTracer()
        
        // When
        let composite = CompositeTracer(
            tracers: [spy1, spy2, spy3],
            minimumLevel: .info,
            parallel: true
        )
        
        // Then - composite created successfully
        let traceId = UUID()
        let event = TraceEvent.agentStart(traceId: traceId, agentName: "TestAgent")
        await composite.trace(event)
        
        // Verify it works
        let spy1Events = await spy1.tracedEvents
        #expect(spy1Events.count == 1)
    }
    
    @Test("CompositeTracer forwards events to all child tracers")
    func forwardsEventsToAllChildTracers() async {
        // Given
        let spy1 = SpyTracer()
        let spy2 = SpyTracer()
        let spy3 = SpyTracer()
        let composite = CompositeTracer(tracers: [spy1, spy2, spy3])
        
        let traceId = UUID()
        let event = TraceEvent.agentStart(
            traceId: traceId,
            agentName: "TestAgent"
        )
        
        // When
        await composite.trace(event)
        
        // Then
        let spy1Events = await spy1.tracedEvents
        let spy2Events = await spy2.tracedEvents
        let spy3Events = await spy3.tracedEvents
        
        #expect(spy1Events.count == 1)
        #expect(spy2Events.count == 1)
        #expect(spy3Events.count == 1)
        
        #expect(spy1Events.first?.kind == .agentStart)
        #expect(spy2Events.first?.kind == .agentStart)
        #expect(spy3Events.first?.kind == .agentStart)
    }
    
    @Test("CompositeTracer filters events below minimum level")
    func filtersEventsBelowMinimumLevel() async {
        // Given
        let spy = SpyTracer()
        let composite = CompositeTracer(
            tracers: [spy],
            minimumLevel: .warning  // Only warning and above
        )
        
        let traceId = UUID()
        
        // When - trace events at different levels
        await composite.trace(TraceEvent.custom(
            traceId: traceId,
            message: "trace level",
            level: .trace
        ))
        await composite.trace(TraceEvent.custom(
            traceId: traceId,
            message: "debug level",
            level: .debug
        ))
        await composite.trace(TraceEvent.custom(
            traceId: traceId,
            message: "info level",
            level: .info
        ))
        await composite.trace(TraceEvent.custom(
            traceId: traceId,
            message: "warning level",
            level: .warning
        ))
        await composite.trace(TraceEvent.custom(
            traceId: traceId,
            message: "error level",
            level: .error
        ))
        
        // Then - only warning and error should be traced
        let tracedEvents = await spy.tracedEvents
        #expect(tracedEvents.count == 2)
        #expect(tracedEvents[0].level == .warning)
        #expect(tracedEvents[1].level == .error)
    }
    
    @Test("CompositeTracer parallel forwarding forwards to all tracers concurrently")
    func parallelForwardingForwardsConcurrently() async {
        // Given
        let spy1 = SpyTracer()
        let spy2 = SpyTracer()
        let spy3 = SpyTracer()
        let composite = CompositeTracer(
            tracers: [spy1, spy2, spy3],
            parallel: true
        )
        
        let traceId = UUID()
        let events = (0..<10).map { index in
            TraceEvent.custom(
                traceId: traceId,
                message: "Event \(index)"
            )
        }
        
        // When - trace multiple events
        for event in events {
            await composite.trace(event)
        }
        
        // Then - all tracers should have all events
        let spy1Events = await spy1.tracedEvents
        let spy2Events = await spy2.tracedEvents
        let spy3Events = await spy3.tracedEvents
        
        #expect(spy1Events.count == 10)
        #expect(spy2Events.count == 10)
        #expect(spy3Events.count == 10)
    }
    
    @Test("CompositeTracer sequential forwarding forwards in order")
    func sequentialForwardingForwardsInOrder() async {
        // Given
        let spy1 = SpyTracer()
        let spy2 = SpyTracer()
        let composite = CompositeTracer(
            tracers: [spy1, spy2],
            parallel: false  // Sequential
        )
        
        let traceId = UUID()
        let event = TraceEvent.agentStart(
            traceId: traceId,
            agentName: "TestAgent"
        )
        
        // When
        await composite.trace(event)
        
        // Then - both spies should have the event
        let spy1Events = await spy1.tracedEvents
        let spy2Events = await spy2.tracedEvents
        
        #expect(spy1Events.count == 1)
        #expect(spy2Events.count == 1)
    }
    
    @Test("CompositeTracer flush calls flush on all children in parallel")
    func flushCallsFlushOnAllChildrenInParallel() async {
        // Given
        let spy1 = SpyTracer()
        let spy2 = SpyTracer()
        let spy3 = SpyTracer()
        let composite = CompositeTracer(
            tracers: [spy1, spy2, spy3],
            parallel: true
        )
        
        // When
        await composite.flush()
        
        // Then
        let spy1FlushCount = await spy1.flushCallCount
        let spy2FlushCount = await spy2.flushCallCount
        let spy3FlushCount = await spy3.flushCallCount
        
        #expect(spy1FlushCount == 1)
        #expect(spy2FlushCount == 1)
        #expect(spy3FlushCount == 1)
    }
    
    @Test("CompositeTracer flush calls flush on all children sequentially")
    func flushCallsFlushOnAllChildrenSequentially() async {
        // Given
        let spy1 = SpyTracer()
        let spy2 = SpyTracer()
        let composite = CompositeTracer(
            tracers: [spy1, spy2],
            parallel: false  // Sequential
        )
        
        // When
        await composite.flush()
        
        // Then
        let spy1FlushCount = await spy1.flushCallCount
        let spy2FlushCount = await spy2.flushCallCount
        
        #expect(spy1FlushCount == 1)
        #expect(spy2FlushCount == 1)
    }
    
    @Test("CompositeTracer with empty tracers array does not crash")
    func emptyTracersArrayDoesNotCrash() async {
        // Given
        let composite = CompositeTracer(tracers: [])
        
        let traceId = UUID()
        let event = TraceEvent.agentStart(
            traceId: traceId,
            agentName: "TestAgent"
        )
        
        // When/Then - should not crash
        await composite.trace(event)
        await composite.flush()
    }
    
    @Test("CompositeTracer filters by minimum level correctly for edge cases")
    func filtersMinimumLevelEdgeCases() async {
        // Given
        let spy = SpyTracer()
        let composite = CompositeTracer(
            tracers: [spy],
            minimumLevel: .info
        )
        
        let traceId = UUID()
        
        // When - trace event exactly at minimum level
        await composite.trace(TraceEvent.custom(
            traceId: traceId,
            message: "exactly info",
            level: .info
        ))
        
        // Then - should be traced
        let tracedEvents = await spy.tracedEvents
        #expect(tracedEvents.count == 1)
        #expect(tracedEvents[0].level == .info)
    }
}

// MARK: - BufferedTracer Tests

@Suite("BufferedTracer Tests")
struct BufferedTracerTests {
    
    @Test("BufferedTracer initializes with destination tracer")
    func initializesWithDestination() async {
        // Given
        let destination = SpyTracer()
        
        // When
        let buffered = BufferedTracer(
            destination: destination,
            maxBufferSize: 100,
            flushInterval: .seconds(5)
        )
        
        // Then - verify it works by tracing
        let traceId = UUID()
        await buffered.trace(TraceEvent.agentStart(traceId: traceId, agentName: "TestAgent"))
        await buffered.flush()
        
        let events = await destination.tracedEvents
        #expect(events.count == 1)
    }
    
    @Test("BufferedTracer buffers events without immediate forwarding")
    func buffersEventsWithoutImmediateForwarding() async {
        // Given
        let destination = SpyTracer()
        let buffered = BufferedTracer(
            destination: destination,
            maxBufferSize: 10
        )
        
        let traceId = UUID()
        let event = TraceEvent.agentStart(
            traceId: traceId,
            agentName: "TestAgent"
        )
        
        // When - trace event but don't flush
        await buffered.trace(event)
        
        // Then - destination should not have the event yet
        let destinationEvents = await destination.tracedEvents
        #expect(destinationEvents.isEmpty)
    }
    
    @Test("BufferedTracer flushes on manual flush call")
    func flushesOnManualFlushCall() async {
        // Given
        let destination = SpyTracer()
        let buffered = BufferedTracer(
            destination: destination,
            maxBufferSize: 100
        )
        
        let traceId = UUID()
        let events = (0..<5).map { index in
            TraceEvent.custom(
                traceId: traceId,
                message: "Event \(index)"
            )
        }
        
        // When - trace events
        for event in events {
            await buffered.trace(event)
        }
        
        // Then - destination should not have events yet
        var destinationEvents = await destination.tracedEvents
        #expect(destinationEvents.isEmpty)
        
        // When - manual flush
        await buffered.flush()
        
        // Then - destination should have all events
        destinationEvents = await destination.tracedEvents
        #expect(destinationEvents.count == 5)
    }
    
    @Test("BufferedTracer auto-flushes when buffer reaches max size")
    func autoFlushesWhenBufferReachesMaxSize() async {
        // Given
        let destination = SpyTracer()
        let buffered = BufferedTracer(
            destination: destination,
            maxBufferSize: 5  // Small buffer for testing
        )
        
        let traceId = UUID()
        
        // When - trace exactly maxBufferSize events
        for index in 0..<5 {
            await buffered.trace(TraceEvent.custom(
                traceId: traceId,
                message: "Event \(index)"
            ))
        }
        
        // Then - should auto-flush
        let destinationEvents = await destination.tracedEvents
        #expect(destinationEvents.count == 5)
    }
    
    @Test("BufferedTracer calls flush on destination during flush")
    func callsFlushOnDestination() async {
        // Given
        let destination = SpyTracer()
        let buffered = BufferedTracer(destination: destination)
        
        let traceId = UUID()
        await buffered.trace(TraceEvent.agentStart(
            traceId: traceId,
            agentName: "TestAgent"
        ))
        
        // When
        await buffered.flush()
        
        // Then
        let flushCount = await destination.flushCallCount
        #expect(flushCount == 1)
    }
    
    @Test("BufferedTracer does not flush empty buffer")
    func doesNotFlushEmptyBuffer() async {
        // Given
        let destination = SpyTracer()
        let buffered = BufferedTracer(destination: destination)
        
        // When - flush without any events
        await buffered.flush()
        
        // Then - flush should not call destination
        let destinationEvents = await destination.tracedEvents
        let flushCount = await destination.flushCallCount
        
        #expect(destinationEvents.isEmpty)
        #expect(flushCount == 0)
    }
    
    @Test("BufferedTracer clears buffer after flush")
    func clearsBufferAfterFlush() async {
        // Given
        let destination = SpyTracer()
        let buffered = BufferedTracer(destination: destination)
        
        let traceId = UUID()
        await buffered.trace(TraceEvent.agentStart(
            traceId: traceId,
            agentName: "TestAgent"
        ))
        
        // When - flush
        await buffered.flush()
        
        // Then - destination has 1 event
        var destinationEvents = await destination.tracedEvents
        #expect(destinationEvents.count == 1)
        
        // When - flush again without new events
        await buffered.flush()
        
        // Then - destination should still have only 1 event (no duplicates)
        destinationEvents = await destination.tracedEvents
        #expect(destinationEvents.count == 1)
    }
    
    @Test("BufferedTracer handles multiple flush cycles")
    func handlesMultipleFlushCycles() async {
        // Given
        let destination = SpyTracer()
        let buffered = BufferedTracer(destination: destination, maxBufferSize: 10)
        
        let traceId = UUID()
        
        // When - first batch
        for index in 0..<3 {
            await buffered.trace(TraceEvent.custom(
                traceId: traceId,
                message: "Batch1-\(index)"
            ))
        }
        await buffered.flush()
        
        // Then
        var destinationEvents = await destination.tracedEvents
        #expect(destinationEvents.count == 3)
        
        // When - second batch
        for index in 0..<2 {
            await buffered.trace(TraceEvent.custom(
                traceId: traceId,
                message: "Batch2-\(index)"
            ))
        }
        await buffered.flush()
        
        // Then - total should be 5
        destinationEvents = await destination.tracedEvents
        #expect(destinationEvents.count == 5)
    }
}

// MARK: - NoOpTracer Tests

@Suite("NoOpTracer Tests")
struct NoOpTracerTests {
    
    @Test("NoOpTracer initializes successfully")
    func initializesSuccessfully() async {
        // When
        let tracer = NoOpTracer()
        
        // Then - verify by using it
        let traceId = UUID()
        await tracer.trace(TraceEvent.agentStart(traceId: traceId, agentName: "TestAgent"))
    }
    
    @Test("NoOpTracer trace does nothing and does not crash")
    func traceDoesNothingAndDoesNotCrash() async {
        // Given
        let tracer = NoOpTracer()
        let traceId = UUID()
        
        let event = TraceEvent.agentStart(
            traceId: traceId,
            agentName: "TestAgent"
        )
        
        // When/Then - should not crash
        await tracer.trace(event)
    }
    
    @Test("NoOpTracer flush does nothing and does not crash")
    func flushDoesNothingAndDoesNotCrash() async {
        // Given
        let tracer = NoOpTracer()
        
        // When/Then - should not crash
        await tracer.flush()
    }
    
    @Test("NoOpTracer handles multiple trace calls")
    func handlesMultipleTraceCalls() async {
        // Given
        let tracer = NoOpTracer()
        let traceId = UUID()
        
        // When - trace many events
        for index in 0..<100 {
            await tracer.trace(TraceEvent.custom(
                traceId: traceId,
                message: "Event \(index)"
            ))
        }
        
        // Then - should not crash
        await tracer.flush()
    }
    
    @Test("NoOpTracer handles all event kinds")
    func handlesAllEventKinds() async {
        // Given
        let tracer = NoOpTracer()
        let traceId = UUID()
        let spanId = UUID()
        
        // When/Then - should not crash for any event kind
        await tracer.trace(TraceEvent.agentStart(traceId: traceId, agentName: "Agent"))
        await tracer.trace(TraceEvent.agentComplete(traceId: traceId, spanId: spanId, agentName: "Agent", duration: 1.0))
        await tracer.trace(TraceEvent.agentError(traceId: traceId, spanId: spanId, agentName: "Agent", error: NSError(domain: "test", code: 1)))
        await tracer.trace(TraceEvent.toolCall(traceId: traceId, parentSpanId: nil, toolName: "Tool"))
        await tracer.trace(TraceEvent.toolResult(traceId: traceId, spanId: spanId, toolName: "Tool", duration: 0.5))
        await tracer.trace(TraceEvent.thought(traceId: traceId, spanId: spanId, agentName: "Agent", thought: "Thinking..."))
        await tracer.trace(TraceEvent.custom(traceId: traceId, message: "Custom"))
    }
}

// MARK: - AnyAgentTracer Tests

@Suite("AnyAgentTracer Tests")
struct AnyAgentTracerTests {
    
    @Test("AnyAgentTracer wraps tracer correctly")
    func wrapsTracerCorrectly() async {
        // Given
        let spy = SpyTracer()
        
        // When
        let wrapped = AnyAgentTracer(spy)
        
        // Then - verify by using it
        let traceId = UUID()
        await wrapped.trace(TraceEvent.agentStart(traceId: traceId, agentName: "TestAgent"))
        
        let spyEvents = await spy.tracedEvents
        #expect(spyEvents.count == 1)
    }
    
    @Test("AnyAgentTracer forwards trace calls to wrapped tracer")
    func forwardsTraceCallsToWrappedTracer() async {
        // Given
        let spy = SpyTracer()
        let wrapped = AnyAgentTracer(spy)
        
        let traceId = UUID()
        let event = TraceEvent.agentStart(
            traceId: traceId,
            agentName: "TestAgent"
        )
        
        // When
        await wrapped.trace(event)
        
        // Then
        let spyEvents = await spy.tracedEvents
        #expect(spyEvents.count == 1)
        #expect(spyEvents.first?.kind == .agentStart)
    }
    
    @Test("AnyAgentTracer forwards flush calls to wrapped tracer")
    func forwardsFlushCallsToWrappedTracer() async {
        // Given
        let spy = SpyTracer()
        let wrapped = AnyAgentTracer(spy)
        
        // When
        await wrapped.flush()
        
        // Then
        let flushCount = await spy.flushCallCount
        #expect(flushCount == 1)
    }
    
    @Test("AnyAgentTracer handles multiple trace calls")
    func handlesMultipleTraceCalls() async {
        // Given
        let spy = SpyTracer()
        let wrapped = AnyAgentTracer(spy)
        
        let traceId = UUID()
        let events = (0..<10).map { index in
            TraceEvent.custom(
                traceId: traceId,
                message: "Event \(index)"
            )
        }
        
        // When
        for event in events {
            await wrapped.trace(event)
        }
        
        // Then
        let spyEvents = await spy.tracedEvents
        #expect(spyEvents.count == 10)
    }
    
    @Test("AnyAgentTracer can wrap NoOpTracer")
    func canWrapNoOpTracer() async {
        // Given
        let noOp = NoOpTracer()
        
        // When
        let wrapped = AnyAgentTracer(noOp)
        
        let traceId = UUID()
        let event = TraceEvent.agentStart(
            traceId: traceId,
            agentName: "TestAgent"
        )
        
        // Then - should not crash
        await wrapped.trace(event)
        await wrapped.flush()
    }
    
    @Test("AnyAgentTracer can be stored in heterogeneous collections")
    func canBeStoredInHeterogeneousCollections() async {
        // Given
        let spy1 = SpyTracer()
        let spy2 = SpyTracer()
        let noOp = NoOpTracer()
        
        let wrapped1 = AnyAgentTracer(spy1)
        let wrapped2 = AnyAgentTracer(spy2)
        let wrapped3 = AnyAgentTracer(noOp)
        
        // When - store in array
        let tracers: [AnyAgentTracer] = [wrapped1, wrapped2, wrapped3]
        
        let traceId = UUID()
        let event = TraceEvent.agentStart(
            traceId: traceId,
            agentName: "TestAgent"
        )
        
        // Then - can iterate and trace
        for tracer in tracers {
            await tracer.trace(event)
        }
        
        let spy1Events = await spy1.tracedEvents
        let spy2Events = await spy2.tracedEvents
        
        #expect(spy1Events.count == 1)
        #expect(spy2Events.count == 1)
    }
}

// MARK: - Integration Tests

@Suite("Tracer Integration Tests")
struct TracerIntegrationTests {
    
    @Test("CompositeTracer with BufferedTracer children")
    func compositeWithBufferedChildren() async {
        // Given
        let destination1 = SpyTracer()
        let destination2 = SpyTracer()
        
        let buffered1 = BufferedTracer(destination: destination1, maxBufferSize: 5)
        let buffered2 = BufferedTracer(destination: destination2, maxBufferSize: 5)
        
        let composite = CompositeTracer(
            tracers: [buffered1, buffered2],
            parallel: true
        )
        
        let traceId = UUID()
        
        // When - trace events
        for index in 0..<5 {
            await composite.trace(TraceEvent.custom(
                traceId: traceId,
                message: "Event \(index)"
            ))
        }
        
        // Then - destinations should have auto-flushed
        let dest1Events = await destination1.tracedEvents
        let dest2Events = await destination2.tracedEvents
        
        #expect(dest1Events.count == 5)
        #expect(dest2Events.count == 5)
    }
    
    @Test("CompositeTracer with mixed tracer types")
    func compositeWithMixedTracerTypes() async {
        // Given
        let spy = SpyTracer()
        let noOp = NoOpTracer()
        let destination = SpyTracer()
        let buffered = BufferedTracer(destination: destination, maxBufferSize: 10)
        
        let composite = CompositeTracer(
            tracers: [spy, noOp, buffered]
        )
        
        let traceId = UUID()
        let event = TraceEvent.agentStart(
            traceId: traceId,
            agentName: "TestAgent"
        )
        
        // When
        await composite.trace(event)
        await composite.flush()
        
        // Then
        let spyEvents = await spy.tracedEvents
        let destinationEvents = await destination.tracedEvents
        
        #expect(spyEvents.count == 1)
        #expect(destinationEvents.count == 1)
    }
    
    @Test("AnyAgentTracer wrapping CompositeTracer")
    func anyTracerWrappingComposite() async {
        // Given
        let spy1 = SpyTracer()
        let spy2 = SpyTracer()
        let composite = CompositeTracer(tracers: [spy1, spy2])
        let wrapped = AnyAgentTracer(composite)
        
        let traceId = UUID()
        let event = TraceEvent.agentStart(
            traceId: traceId,
            agentName: "TestAgent"
        )
        
        // When
        await wrapped.trace(event)
        
        // Then
        let spy1Events = await spy1.tracedEvents
        let spy2Events = await spy2.tracedEvents
        
        #expect(spy1Events.count == 1)
        #expect(spy2Events.count == 1)
    }
}

// MARK: - Edge Case Tests

@Suite("Tracer Edge Case Tests")
struct TracerEdgeCaseTests {
    
    @Test("CompositeTracer with single tracer")
    func compositeWithSingleTracer() async {
        // Given
        let spy = SpyTracer()
        let composite = CompositeTracer(tracers: [spy])
        
        let traceId = UUID()
        let event = TraceEvent.agentStart(
            traceId: traceId,
            agentName: "TestAgent"
        )
        
        // When
        await composite.trace(event)
        
        // Then
        let spyEvents = await spy.tracedEvents
        #expect(spyEvents.count == 1)
    }
    
    @Test("BufferedTracer with maxBufferSize of 1")
    func bufferedWithMaxBufferSizeOne() async {
        // Given
        let destination = SpyTracer()
        let buffered = BufferedTracer(destination: destination, maxBufferSize: 1)
        
        let traceId = UUID()
        
        // When - trace one event
        await buffered.trace(TraceEvent.agentStart(
            traceId: traceId,
            agentName: "TestAgent"
        ))
        
        // Then - should auto-flush immediately
        let destinationEvents = await destination.tracedEvents
        #expect(destinationEvents.count == 1)
    }
    
    @Test("CompositeTracer with all event levels")
    func compositeWithAllEventLevels() async {
        // Given
        let spy = SpyTracer()
        let composite = CompositeTracer(
            tracers: [spy],
            minimumLevel: .trace  // Accept all levels
        )
        
        let traceId = UUID()
        
        // When - trace all levels
        for level in EventLevel.allCases {
            await composite.trace(TraceEvent.custom(
                traceId: traceId,
                message: "Level: \(level)",
                level: level
            ))
        }
        
        // Then - all should be traced
        let spyEvents = await spy.tracedEvents
        #expect(spyEvents.count == EventLevel.allCases.count)
    }
    
    @Test("BufferedTracer with very large maxBufferSize")
    func bufferedWithVeryLargeMaxBufferSize() async {
        // Given
        let destination = SpyTracer()
        let buffered = BufferedTracer(
            destination: destination,
            maxBufferSize: 10000
        )
        
        let traceId = UUID()
        
        // When - trace many events (but less than buffer size)
        for index in 0..<100 {
            await buffered.trace(TraceEvent.custom(
                traceId: traceId,
                message: "Event \(index)"
            ))
        }
        
        // Then - should not auto-flush
        var destinationEvents = await destination.tracedEvents
        #expect(destinationEvents.isEmpty)
        
        // When - manual flush
        await buffered.flush()
        
        // Then - all events should be flushed
        destinationEvents = await destination.tracedEvents
        #expect(destinationEvents.count == 100)
    }
}
