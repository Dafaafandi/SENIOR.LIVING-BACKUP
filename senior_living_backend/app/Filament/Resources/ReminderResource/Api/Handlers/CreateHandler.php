<?php
namespace App\Filament\Resources\ReminderResource\Api\Handlers;

use Illuminate\Http\Request;
use Rupadana\ApiService\Http\Handlers;
use App\Filament\Resources\ReminderResource;
use App\Filament\Resources\ReminderResource\Api\Requests\CreateReminderRequest;

class CreateHandler extends Handlers {
    public static string | null $uri = '/';
    public static string | null $resource = ReminderResource::class;

    public static bool $public = true;
    public static function getMethod()
    {
        return Handlers::POST;
    }

    public static function getModel() {
        return static::$resource::getModel();
    }

    /**
     * Create Reminder
     *
     * @param CreateReminderRequest $request
     * @return \Illuminate\Http\JsonResponse
     */
    public function handler(CreateReminderRequest $request)
    {
        $model = new (static::getModel());

        $model->fill($request->all());

        $model->save();

        return static::sendSuccessResponse($model, "Successfully Create Resource");
    }
}
