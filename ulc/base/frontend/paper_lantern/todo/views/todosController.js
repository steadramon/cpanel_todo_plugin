/* global define: false */

/* Copyright (c) 2016, cPanel, Inc.
All rights reserved.
http://cpanel.net

Redistribution and use in source and binary forms, with or without
modification, are permitted provided that the following conditions are met:

1. Redistributions of source code must retain the above copyright notice,
this list of conditions and the following disclaimer.

2. Redistributions in binary form must reproduce the above copyright notice,
this list of conditions and the following disclaimer in the documentation
and/or other materials provided with the distribution.

3. Neither the name of the owner nor the names of its contributors may be
used to endorse or promote products derived from this software without
specific prior written permission.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE
FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE. */

define(
    [
        "angular",
        "cjt/services/alertService",
        "app/services/todoAPI"
    ],
    function(angular) {

        // Retrieve the current application
        var app = angular.module("App");

        var controller = app.controller(
            "todosController", [
                "$scope",
                "alertService",
                "todoAPI",
                "todoData",
                function(
                    $scope,
                    alertService,
                    todoAPI,
                    todoData
                ) {
                    var list = function() {
                        todoAPI.list().then(function(resp) {
                            todoData.todos = $scope.todos = resp.data;
                            if ($scope.todos && $scope.todos.length > 0) {
                                alertService.add({
                                    type: "info",
                                    message: "Loaded the data",
                                    id: "loadedOk"
                                });
                            }
                        }).catch(function(error) {
                            alertService.add({
                                type: "danger",
                                message: "Faild to load the data: " + error,
                                id: "loadFailed"
                            });
                        });
                    };

                    $scope.open_add_view = function() {
                        $scope.newTodo = {
                            subject: "",
                            description: ""
                        };
                        $scope.loadView("todo/new");
                    };

                    $scope.add = function(todo) {
                        $scope.saving = true;
                        todoAPI.add(todo).then(function(resp) {
                            $scope.todos.push(resp.data);
                            alertService.add({
                                type: "info",
                                message: "Added the new todo.",
                                id: "addOk"
                            });
                            $scope.saving = false;
                            $scope.loadView("todos");
                        }).catch(function(error) {
                            alertService.add({
                                type: "danger",
                                message: "Failed to add the new todo: " + error,
                                id: "addFailed"
                            });
                        });
                    };

                    $scope.mark = function(todo) {
                        todoAPI.mark(todo).then(function(resp) {
                            todo.status  = resp.data.status;
                            todo.doned   = resp.data.doned;
                            todo.changed = resp.data.changed;
                        }).catch(function(error) {
                            alertService.add({
                                type: "danger",
                                message: "Failed to add the mark the todo: " + error,
                                id: "markFailed"
                            });
                        });
                    };


                    if (!todoData.todos) {
                        list();
                    } else {
                        $scope.todos = todoData.todos;
                    }
                }
            ]
        );

        return controller;
    }
);