<?php
namespace App\Filament\Resources\HospitalVisitResource\Api;

use Rupadana\ApiService\ApiService;
use App\Filament\Resources\HospitalVisitResource;
use Illuminate\Routing\Router;


class HospitalVisitApiService extends ApiService
{
    protected static string | null $resource = HospitalVisitResource::class;

    public static function handlers() : array
    {
        return [
            Handlers\PaginationHandler::class,
            Handlers\DetailHandler::class,
            Handlers\CreateHandler::class,
            Handlers\UpdateHandler::class,
            Handlers\DeleteHandler::class
        ];

    }
}
