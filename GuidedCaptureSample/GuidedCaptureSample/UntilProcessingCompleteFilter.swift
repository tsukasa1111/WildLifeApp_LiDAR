import RealityKit

struct UntilProcessingCompleteFilter<Base>: AsyncSequence, AsyncIteratorProtocol
        where Base: AsyncSequence, Base.Element == PhotogrammetrySession.Output {
    func makeAsyncIterator() -> UntilProcessingCompleteFilter {
        return self
    }

    typealias AsyncIterator = Self
    typealias Element = PhotogrammetrySession.Output

    private let inputSequence: Base
    private var completed: Bool = false
    private var iterator: Base.AsyncIterator

    init(input: Base) where Base.Element == Element {
        inputSequence = input
        iterator = inputSequence.makeAsyncIterator()
    }

    mutating func next() async -> Element? {
        if completed {
            return nil
        }

        guard let element = try? await iterator.next() else {
            completed = true
            return nil
        }

        if case Element.processingComplete = element {
            completed = true
        }
        if case Element.processingCancelled = element {
            completed = true
        }

        return element
    }
}

