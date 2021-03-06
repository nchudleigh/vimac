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
}
