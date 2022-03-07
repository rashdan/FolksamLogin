//
//  Service.swift
//  Home
//
//  Created by Johan Torell on 2021-02-09.
//

import Foundation

public protocol LoginServiceProtocol {
    func startBankID(pnr: String, completion: @escaping (Result<Bool, Error>) -> Void)
}
