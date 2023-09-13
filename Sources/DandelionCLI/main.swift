//
//  main.swift
//  
//
//  Created by Mafalda on 9/12/23.
//

import ArgumentParser
import Foundation

struct DandelionCLI: ParsableCommand
{
    static let configuration = CommandConfiguration(
        commandName: "Dandelion",
        subcommands: [
            New.self,
            Run.self
        ]
    )
}

extension DandelionCLI
{
    struct New: ParsableCommand
    {
        @Argument(help: "The program you want to create a new setup for. Possible options are: \(Petal.backendServer), or \(Petal.backendClient)")
        var petal: Petal
        
        @Argument(help: "The port that the server listens on.")
        var port: Int
        
        @Flag(help: "Whether or not to overwrite the setup if one already exists.")
        var overwrite = false
        
        func run() throws
        {
            print("Creating a new Dandelion setup...")
            
            switch petal
            {
                case .backendServer:
                    print("A new backend server setup was requested.")
                    print("😶 This code has not yet been implemented!")
                case .backendClient:
                    print("A new backend client setup was requested.")
                    print("😶 This code has not yet been implemented!")
                case .frontendServer:
                    print("A new frontend server setup was requested.")
                    print("😶 This code has not yet been implemented!")
                case .frontendClient:
                    print("A new frontend client setup was requested.")
                    print("😶 This code has not yet been implemented!")
            }
        }
    }
}

extension DandelionCLI
{
    struct Run: ParsableCommand
    {
        func run() throws {
            print("😶 This code has not yet been implemented!")
        }
    }
}

DandelionCLI.main()


enum Petal: String, ExpressibleByArgument
{
    case backendServer
    case backendClient
    case frontendServer
    case frontendClient
}
