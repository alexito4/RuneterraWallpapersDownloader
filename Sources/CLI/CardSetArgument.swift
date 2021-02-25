//
//  Created by Alex on 25/2/21.
//

import ArgumentParser
import RuneterraWallpapersDownloader

extension CardSet: ExpressibleByArgument {
    public init?(argument: String) {
        for set in zip(1..., CardSet.all) where "\(set.0)" == argument {
            self = set.1
            return
        }
        return nil
    }
}
