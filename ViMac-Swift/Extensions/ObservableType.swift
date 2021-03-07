import Cocoa
import RxSwift

// Taken from https://stackoverflow.com/a/53661320/10390454
extension ObservableType {
    func withPrevious() -> Observable<(Element?, Element)> {
        return scan([], accumulator: { (previous, current) in
            Array(previous + [current]).suffix(2)
        })
        .map({ (arr) -> (previous: Element?, current: Element) in
            (arr.count > 1 ? arr.first : nil, arr.last!)
        })
    }
    
    func onlyWhen(_ predicate: Observable<Bool>) -> Observable<Element> {
        withLatestFrom(
            predicate,
            resultSelector: { ($0, $1) }
        )
        .filter { $0.1 }
        .map { $0.0 }
    }
}
