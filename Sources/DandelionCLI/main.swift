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
        @Argument(help: "The port that the server frontend listens on.")
        var frontendPort: Int
        
        @Argument(help: "The port that the server backend listens on.")
        var backendPort: Int
        
        @Flag(help: "Whether or not to overwrite the setup if one already exists.")
        var overwrite = false
        
        func run() throws
        {
            print("Creating a new Dandelion setup...")
            print("A new server setup was requested.")
            print("😶 This code has not yet been implemented!")
        }
    }
}

extension DandelionCLI
{
    struct Run: ParsableCommand
    {
        @Argument(help: "The type of server you want to run. Possible options are: \(Petal.server)")
        var program: Petal
        
        func run() throws
        {
            print("Running a Dandelion server...")
            
            switch program
            {
                case .server:
                    print("A new server setup was requested.")
                    print("😶 This code has not yet been implemented!")
                case .backendClient:
                    print("🔺 A new backend client setup was requested. Try running a server instead!")
                case .frontendClient:
                    print("🔺 A new frontend client setup was requested. Try running a server instead!")
            }
        }
    }
}

DandelionCLI.main()


enum Petal: String, ExpressibleByArgument
{
    case server
    case backendClient
    case frontendClient
}
