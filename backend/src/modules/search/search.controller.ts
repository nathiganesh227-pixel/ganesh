import { Controller, Get, Query } from '@nestjs/common';
import { ApiTags, ApiOperation } from '@nestjs/swagger';
import { SearchService, GlobalSearchResult } from './search.service';

@ApiTags('search')
@Controller('search')
export class SearchController {
  constructor(private readonly service: SearchService) {}

  @Get()
  @ApiOperation({ summary: 'Cross-vertical search across all 7 categories' })
  async searchAll(@Query('q') q = ''): Promise<GlobalSearchResult> {
    return this.service.searchAll(q);
  }
}
