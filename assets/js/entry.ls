

setup-routes = ($route-provider) ->
    $route-provider.when '/',               { controller: 'appCtrl',     template-url: '/html/example-view.html'   }
                   .otherwise redirect-to: '/'

#Main entry point of the application
application = angular.module('application', ['ui.bootstrap.datetimepicker', 'ngRoute'])

application.config(setup-routes)

application.controller 'appCtrl', ($scope) ->
    $scope.status = 'ok'

