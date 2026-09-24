import { Module } from '@nestjs/common';
import { MoviesModule } from '../movies/movies.module';
import { DiningModule } from '../dining/dining.module';
import { EventsModule } from '../events/events.module';
import { ActivitiesModule } from '../activities/activities.module';
import { ShoppingModule } from '../shopping/shopping.module';
import { StaysModule } from '../stays/stays.module';
import { SportsModule } from '../sports/sports.module';
import { SearchService } from './search.service';
import { SearchController } from './search.controller';

@Module({
  imports: [
    MoviesModule,
    DiningModule,
    EventsModule,
    ActivitiesModule,
    ShoppingModule,
    StaysModule,
    SportsModule,
  ],
  controllers: [SearchController],
  providers: [SearchService],
  exports: [SearchService],
})
export class SearchModule {}
