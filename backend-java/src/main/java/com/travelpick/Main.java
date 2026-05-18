package com.travelpick;

import com.sun.net.httpserver.HttpServer;
import com.travelpick.config.AppConfig;
import com.travelpick.http.ApiHandler;
import com.travelpick.service.DestinationService;
import com.travelpick.service.GroupService;
import com.travelpick.service.ResultsService;
import com.travelpick.service.UserService;
import com.travelpick.service.VoteService;
import com.travelpick.store.DataStore;
import java.io.IOException;
import java.net.InetSocketAddress;
import java.util.concurrent.Executors;

/** Entry point for the pure Java TravelPick HTTP backend. */
public final class Main {

    public static void main(String[] args) throws IOException {
        for (String arg : args) {
            if ("--reset".equalsIgnoreCase(arg)) {
                System.out.println("Are you sure you want to reset all data?");
                System.out.print("Type 'yes' or 'y' to confirm: ");
                java.io.BufferedReader reader = new java.io.BufferedReader(new java.io.InputStreamReader(System.in));
                String line = reader.readLine();
                if (line != null && ("yes".equalsIgnoreCase(line.trim()) || "y".equalsIgnoreCase(line.trim()))) {
                    DataStore store = new DataStore();
                    store.resetData();
                    System.out.println("All system data has been reset successfully.");
                    System.exit(0);
                } else {
                    System.out.println("Reset cancelled.");
                    System.exit(0);
                }
            }
        }

        DataStore store = new DataStore();
        GroupService groupService = new GroupService(store);
        UserService userService = new UserService(store);
        DestinationService destinationService = new DestinationService(store);
        VoteService voteService = new VoteService(store, userService, groupService, destinationService);
        ResultsService resultsService = new ResultsService(store, groupService, destinationService);

        HttpServer server = HttpServer.create(new InetSocketAddress(AppConfig.PORT), 0);
        server.createContext("/", new ApiHandler(
                groupService, userService, destinationService, voteService, resultsService, store));
        server.setExecutor(Executors.newFixedThreadPool(8));
        server.start();

        System.out.println("TravelPick backend running on http://127.0.0.1:" + AppConfig.PORT);
        System.out.println("Data directory: " + AppConfig.getDataDir());
    }

    private Main() {
    }
}
